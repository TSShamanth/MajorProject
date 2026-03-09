import 'package:flutter/material.dart';
import 'package:flutter_application/models/department_model.dart';
import 'package:flutter_application/models/section_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/services/api_service.dart';
import '../widgets/admin_layout.dart';
import '../services/session_manager.dart';

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
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final id = await SessionManager.getInstitutionId();
    if (mounted) {
      setState(() {
        _institutionId = id;
      });
    }
    if (id != null) {
      await _fetchDepartments();
      await _fetchAllUsers();
    }
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
        SnackBar(content: Text('Failed to fetch users: $e'), behavior: SnackBarBehavior.floating),
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
        SnackBar(content: Text('Failed to fetch departments: $e'), behavior: SnackBarBehavior.floating),
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
        SnackBar(content: Text('Failed to fetch sections: $e'), behavior: SnackBarBehavior.floating),
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
          backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          title: Text('Add New Section', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)),
          content: TextField(
            controller: nameController,
            style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
            decoration: _inputDecoration("Section Name", Icons.grid_view_rounded),
            autofocus: true,
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              child: const Text('Create'),
              onPressed: () async {
                if (nameController.text.isNotEmpty && _institutionId != null && _selectedDepartment != null) {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(dialogContext);
                  final newSection = Section(
                    name: nameController.text,
                    departmentId: _selectedDepartment!.id,
                    institutionId: _institutionId!,
                    studentIds: [],
                  );
                  try {
                    await _apiService.createSection(_institutionId!, _selectedDepartment!.id, newSection);
                    if (mounted) navigator.pop(true);
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
                      navigator.pop(false);
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );

    if (shouldRefresh == true) _fetchSections();
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
              backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              title: Text('Enroll Students', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)),
              content: SizedBox(
                width: 400,
                child: students.isEmpty 
                  ? const Padding(padding: EdgeInsets.all(20), child: Text('No unassigned students found.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final isSelected = selectedStudentIds.contains(student.uid);
                        return CheckboxListTile(
                          title: Text(student.displayName, style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)),
                          subtitle: Text(student.usn ?? '', style: TextStyle(color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!)),
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
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(dialogContext);
                    final newStudentIds = [...section.studentIds, ...selectedStudentIds];
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
                      if (mounted) navigator.pop();
                      _fetchSections();
                    } catch (e) {
                      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
                    }
                  },
                  child: const Text('Enroll'),
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
    if (section.facultyId != null) allAssignedFacultyIds.remove(section.facultyId);
    
    final faculties = _allUsers.where((user) => user.role == 'faculty' && !allAssignedFacultyIds.contains(user.uid)).toList();

    if (!mounted) return;
    final selectedFacultyId = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          title: Text('Assign Class Teacher', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)),
          content: SizedBox(
            width: 400,
            child: faculties.isEmpty 
              ? const Padding(padding: EdgeInsets.all(20), child: Text('No available faculty found.'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: faculties.length,
                  itemBuilder: (context, index) {
                    final faculty = faculties[index];
                    return ListTile(
                      title: Text(faculty.displayName, style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)),
                      onTap: () => Navigator.of(dialogContext).pop(faculty.uid),
                    );
                  },
                ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel'))],
        );
      },
    );

    if (!mounted) return;
    if (selectedFacultyId != null) {
      final messenger = ScaffoldMessenger.of(context);
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
        if (mounted) messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  void _removeStudent(Section section, String studentId) async {
    final messenger = ScaffoldMessenger.of(context);
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
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!),
      prefixIcon: Icon(icon, color: const Color(0xFF4F46E5).withOpacity(0.7), size: 20),
      filled: true,
      fillColor: _isDarkMode ? const Color(0xFF111827).withOpacity(0.5) : Colors.grey[50]!,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: 'Class Management',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Class & Section', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: _isLoadingDepartments || _isLoadingUsers
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Academic Organization', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text('Manage sections, students, and faculty assignments for each department', style: TextStyle(fontSize: 14, color: textSecondary)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _addSection,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add New Section'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  _buildDepartmentSelector(textPrimary, textSecondary),
                  const SizedBox(height: 24),
                  
                  Expanded(
                    child: _isLoadingSections
                        ? const Center(child: CircularProgressIndicator())
                        : _sections.isEmpty
                            ? _buildEmptyState(textSecondary)
                            : _buildSectionsList(textPrimary, textSecondary),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDepartmentSelector(Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(Icons.business_rounded, color: const Color(0xFF4F46E5), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Department>(
                value: _selectedDepartment,
                isExpanded: true,
                dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                onChanged: (Department? newValue) {
                  setState(() {
                    _selectedDepartment = newValue;
                    _fetchSections();
                  });
                },
                items: _departments.map<DropdownMenuItem<Department>>((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsList(Color textPrimary, Color textSecondary) {
    return ListView.builder(
      itemCount: _sections.length,
      itemBuilder: (context, index) {
        final section = _sections[index];
        final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
        final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.grid_view_rounded, color: Color(0xFF10B981), size: 20),
            ),
            title: Text(section.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary)),
            subtitle: Text('${section.studentIds.length} Students enrolled', style: TextStyle(fontSize: 13, color: textSecondary)),
            children: [
              const Divider(height: 1),
              _buildFacultyTile(section, textPrimary, textSecondary),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Student Roster', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                    TextButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Student'),
                      onPressed: () => _addStudent(section),
                    ),
                  ],
                ),
              ),
              ...section.studentIds.map((sid) => _buildStudentTile(section, sid, textPrimary, textSecondary)),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFacultyTile(Section section, Color textPrimary, Color textSecondary) {
    final facultyName = section.facultyId != null ? _getUserName(section.facultyId!) : 'Not Assigned';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: const Icon(Icons.person_pin_rounded, color: Color(0xFF8B5CF6), size: 20),
      title: Text('Class Teacher', style: TextStyle(fontSize: 12, color: textSecondary)),
      subtitle: Text(facultyName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
      trailing: IconButton(
        icon: const Icon(Icons.edit_rounded, size: 18),
        onPressed: () => _assignFaculty(section),
        tooltip: 'Change Faculty',
      ),
    );
  }

  Widget _buildStudentTile(Section section, String studentId, Color textPrimary, Color textSecondary) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: const CircleAvatar(radius: 14, backgroundColor: Color(0xFFF3F4F6), child: Icon(Icons.person_rounded, size: 16, color: Colors.grey)),
      title: Text(_getUserName(studentId), style: TextStyle(fontSize: 14, color: textPrimary)),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 18),
        onPressed: () => _removeStudent(section, studentId),
        tooltip: 'Remove from Section',
      ),
    );
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 64, color: textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No sections found for this department', style: TextStyle(fontSize: 16, color: textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
