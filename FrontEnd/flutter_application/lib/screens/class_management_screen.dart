import 'package:flutter/material.dart';
import 'package:flutter_application/models/department_model.dart';
import 'package:flutter_application/models/section_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:go_router/go_router.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  final ApiService _apiService = ApiService();
  String? _institutionId;
  List<Department> _departments = [];
  Department? _selectedDepartment;
  List<Section> _sections = [];
  List<UserModel> _allUsers = [];
  bool _isLoadingDepartments = true;
  bool _isLoadingSections = false;
  bool _isLoadingUsers = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    final routeState = router.routerDelegate.currentConfiguration;
    final pathParams = routeState.pathParameters;
    _institutionId = pathParams['institutionId'];
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    if (_institutionId == null) return;
    await _fetchDepartments();
    await _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    if (_institutionId == null) return;
    try {
      final users = await _apiService.getUsers(_institutionId!);
      if (!mounted) return;
      setState(() {
        _allUsers = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingUsers = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch users: $e')),
      );
    }
  }

  String _getUserName(String userId) {
    try {
      return _allUsers.firstWhere((user) => user.uid == userId).displayName;
    } catch (e) {
      return 'Unknown User';
    }
  }

  Future<void> _fetchDepartments() async {
    if (_institutionId == null) return;
    try {
      final departments = await _apiService.getDepartments(_institutionId!);
      if (!mounted) return;
      setState(() {
        _departments = departments;
        if (_departments.isNotEmpty) {
          _selectedDepartment = _departments.first;
          _fetchSections();
        }
        _isLoadingDepartments = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingDepartments = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch departments: $e')),
      );
    }
  }

  Future<void> _fetchSections() async {
    if (_institutionId == null || _selectedDepartment == null) return;
    setState(() {
      _isLoadingSections = true;
    });
    try {
      final sections = await _apiService.getSections(_institutionId!, _selectedDepartment!.id);
      if (!mounted) return;
      setState(() {
        _sections = sections;
        _isLoadingSections = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSections = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch sections: $e')),
      );
    }
  }
  
  List<String> _getAllAssignedStudentIds() {
    return _sections.expand((section) => section.studentIds).toList();
  }

  List<String> _getAllAssignedFacultyIds() {
    return _sections.where((section) => section.facultyId != null).map((section) => section.facultyId!).toList();
  }


  Future<void> _addSection() async {
    final nameController = TextEditingController();
    final shouldRefresh = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add New Section'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "Section Name"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            ElevatedButton(
              child: const Text('Create'),
              onPressed: () async {
                if (nameController.text.isNotEmpty && _institutionId != null && _selectedDepartment != null) {
                  final newSection = Section(
                    name: nameController.text,
                    departmentId: _selectedDepartment!.id,
                    institutionId: _institutionId!,
                    studentIds: [],
                  );
                  final dialogNavigator = Navigator.of(dialogContext);
                  try {
                    await _apiService.createSection(_institutionId!, _selectedDepartment!.id, newSection);
                    if (dialogNavigator.mounted) {
                      dialogNavigator.pop(true);
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create section: $e')),
                    );
                    if (dialogNavigator.mounted) {
                      dialogNavigator.pop(false);
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );

    if (shouldRefresh == true) {
      _fetchSections();
    }
  }

  void _addStudent(Section section) {
    final allAssignedStudentIds = _getAllAssignedStudentIds();
    final students = _allUsers.where((user) => user.role == 'student' && !allAssignedStudentIds.contains(user.uid)).toList();
    List<String> selectedStudentIds = [];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (innerDialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Add Students'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final isSelected = selectedStudentIds.contains(student.uid);
                    return CheckboxListTile(
                      title: Text(student.displayName),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedStudentIds.add(student.uid);
                          } else {
                            selectedStudentIds.remove(student.uid);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newStudentIds = [...section.studentIds, ...selectedStudentIds];
                    final updatedSection = Section(
                      id: section.id,
                      name: section.name,
                      departmentId: section.departmentId,
                      institutionId: section.institutionId,
                      facultyId: section.facultyId,
                      studentIds: newStudentIds,
                    );
                    final dialogNavigator = Navigator.of(dialogContext);
                    try {
                      await _apiService.updateSection(_institutionId!, _selectedDepartment!.id, section.id!, updatedSection);
                      if (dialogNavigator.mounted) {
                        dialogNavigator.pop();
                      }
                      _fetchSections();
                    } catch (e) {
                      if (!mounted) return;
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add students: $e')),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _assignFaculty(Section section) async {
    final allAssignedFacultyIds = _getAllAssignedFacultyIds();
    if (section.facultyId != null) {
      allAssignedFacultyIds.remove(section.facultyId);
    }
    final faculties = _allUsers.where((user) => user.role == 'faculty' && !allAssignedFacultyIds.contains(user.uid)).toList();

    final selectedFacultyId = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Assign Faculty'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: faculties.length,
              itemBuilder: (context, index) {
                final faculty = faculties[index];
                return ListTile(
                  title: Text(faculty.displayName),
                  onTap: () {
                    Navigator.of(dialogContext).pop(faculty.uid);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedFacultyId != null && _institutionId != null && _selectedDepartment != null) {
      final updatedSection = Section(
        id: section.id,
        name: section.name,
        departmentId: section.departmentId,
        institutionId: section.institutionId,
        facultyId: selectedFacultyId,
        studentIds: section.studentIds,
      );

      try {
        await _apiService.updateSection(_institutionId!, _selectedDepartment!.id, section.id!, updatedSection);
        _fetchSections();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign faculty: $e')),
        );
      }
    }
  }

  void _removeStudent(Section section, String studentId) async {
    final newStudentIds = section.studentIds.where((id) => id != studentId).toList();
    final updatedSection = Section(
      id: section.id,
      name: section.name,
      departmentId: section.departmentId,
      institutionId: section.institutionId,
      facultyId: section.facultyId,
      studentIds: newStudentIds,
    );

    try {
      await _apiService.updateSection(_institutionId!, _selectedDepartment!.id, section.id!, updatedSection);
      _fetchSections();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove student: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class & Section Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _isLoadingDepartments || _isLoadingUsers
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildDepartmentSelector(),
                Expanded(
                  child: _isLoadingSections
                      ? const Center(child: CircularProgressIndicator())
                      : _sections.isEmpty
                          ? const Center(child: Text('No sections found for this department.'))
                          : _buildSectionsList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSection,
        tooltip: 'Add Section',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDepartmentSelector() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: DropdownButtonFormField<Department>(
        value: _selectedDepartment,
        decoration: const InputDecoration(
          labelText: 'Select Program/Batch',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (Department? newValue) {
          setState(() {
            _selectedDepartment = newValue;
            _fetchSections();
          });
        },
        items: _departments.map<DropdownMenuItem<Department>>((Department department) {
          return DropdownMenuItem<Department>(
            value: department,
            child: Text(department.name),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _sections.length,
      itemBuilder: (context, index) {
        final section = _sections[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            shape: Border.all(color: Colors.transparent),
            title: Text(section.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text('${section.studentIds.length} Students'),
            children: [
              ListTile(
                title: Text('Faculty: ${section.facultyId != null ? _getUserName(section.facultyId!) : 'Not Assigned'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _assignFaculty(section),
                ),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Students', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...section.studentIds.map((studentId) {
                return ListTile(
                  title: Text(_getUserName(studentId)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      _removeStudent(section, studentId);
                    },
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Student'),
                  onPressed: () => _addStudent(section),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
