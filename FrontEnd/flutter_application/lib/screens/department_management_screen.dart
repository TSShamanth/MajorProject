import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../config/api_config.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';

class DepartmentManagementScreen extends StatefulWidget {
  final String departmentName;
  final String assetType; // 'Courses', 'Faculty', or 'Students'

  const DepartmentManagementScreen({
    super.key,
    required this.departmentName,
    required this.assetType,
  });

  @override
  State<DepartmentManagementScreen> createState() =>
      _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState
    extends State<DepartmentManagementScreen> {
  late Future<List<dynamic>> _itemsFuture;
  List<UserModel> _faculty = [];
  List<UserModel> _students = [];
  String? _departmentId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchDepartmentId();
    if (_departmentId != null) {
      _itemsFuture = _fetchData();
      _fetchUsers();
    }
  }

  Future<void> _fetchDepartmentId() async {
    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) return;
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/departments'));
    if (response.statusCode == 200) {
      final List<dynamic> departments = json.decode(response.body);
      final department = departments.firstWhere(
        (d) => d['name'] == widget.departmentName,
        orElse: () => null,
      );
      if (department != null) {
        setState(() {
          _departmentId = department['id'];
        });
      }
    }
  }
  
  Future<List<dynamic>> _fetchData() async {
    if (_departmentId == null) return [];
    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) return [];

    switch (widget.assetType) {
      case 'Courses':
        final response = await http.get(Uri.parse(
            '${ApiConfig.baseUrl}/$institutionId/api/departments/$_departmentId/courses'));
        if (response.statusCode == 200) {
          final List<dynamic> courses = json.decode(response.body);
          return courses.map((c) => Course.fromJson(c)).toList();
        } else {
          throw Exception('Failed to load courses');
        }
      // Add cases for Faculty and Students later
      default:
        return [];
    }
  }

  Future<void> _fetchUsers() async {
    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) return;
    
    final apiService = ApiService();
    try {
      final users = await apiService.getUsers(institutionId);
      setState(() {
        _faculty = users.where((user) => user.role == 'faculty').toList();
        _students = users.where((user) => user.role == 'student').toList();
      });
    } catch (e) {
      // Handle error
    }
  }

  void _addItem() {
    if (widget.assetType == 'Courses') {
      _showAddCourseDialog();
    }
    // Handle other asset types later
  }

  void _showAddCourseDialog({Course? course}) {
    final courseCodeController = TextEditingController(text: course?.courseCode);
    final courseNameController = TextEditingController(text: course?.courseName);
    final programController = TextEditingController(text: course?.program);
    final semesterController = TextEditingController(text: course?.semester);
    final totalClassesController = TextEditingController(text: course?.totalClasses);
    String? selectedFacultyId = course?.facultyUid;
    List<String> selectedStudentIds = course?.studentsEnrolled ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(course == null ? 'Add New Course' : 'Edit Course'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: courseCodeController, decoration: const InputDecoration(labelText: 'Course Code')),
                    TextField(controller: courseNameController, decoration: const InputDecoration(labelText: 'Course Name')),
                    DropdownButtonFormField<String>(
                      value: selectedFacultyId,
                      hint: const Text('Select Faculty'),
                      items: _faculty.map((user) {
                        return DropdownMenuItem(value: user.uid, child: Text(user.displayName));
                      }).toList(),
                      onChanged: (value) => setDialogState(() => selectedFacultyId = value),
                    ),
                    TextField(controller: programController, decoration: const InputDecoration(labelText: 'Program (e.g., BTech)')),
                    TextField(controller: semesterController, decoration: const InputDecoration(labelText: 'Semester')),
                    TextField(controller: totalClassesController, decoration: const InputDecoration(labelText: 'Total Classes')),
                      MultiSelectDialogField(
                      items: _students.map((s) => MultiSelectItem(s.uid, s.displayName)).toList(),
                      title: const Text("Students"),
                      selectedColor: Theme.of(context).primaryColor,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        border: Border.all(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      buttonIcon: const Icon(
                        Icons.school,
                        color: Colors.grey,
                      ),
                      buttonText: Text(
                        "Enrolled Students",
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 16,
                        ),
                      ),
                      onConfirm: (results) {
                        selectedStudentIds = List<String>.from(results);
                      },
                      initialValue: selectedStudentIds,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
                ElevatedButton(
                  child: Text(course == null ? 'Add' : 'Save'),
                  onPressed: () async {
                    if (courseCodeController.text.isNotEmpty && courseNameController.text.isNotEmpty && selectedFacultyId != null) {
                      final institutionId = await SessionManager.getInstitutionId();
                       if (institutionId == null || _departmentId == null) return;

                      final newCourse = Course(
                        courseCode: courseCodeController.text,
                        courseName: courseNameController.text,
                        facultyUid: selectedFacultyId!,
                        institutionId: institutionId,
                        program: programController.text,
                        semester: semesterController.text,
                        studentsEnrolled: selectedStudentIds,
                        totalClasses: totalClassesController.text,
                      );

                      final url = course == null
                          ? '${ApiConfig.baseUrl}/$institutionId/api/departments/$_departmentId/courses'
                          : '${ApiConfig.baseUrl}/$institutionId/api/departments/$_departmentId/courses/${course.courseCode}';
                      
                      final response = await (course == null
                          ? http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: json.encode(newCourse.toJson()))
                          : http.put(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: json.encode(newCourse.toJson())));

                      if (response.statusCode == 200) {
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        setState(() => _itemsFuture = _fetchData());
                      } else {
                        // Handle error
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editItem(dynamic item) {
    if (widget.assetType == 'Courses' && item is Course) {
      _showAddCourseDialog(course: item);
    }
  }

  void _deleteItem(dynamic item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete ${widget.assetType.singular}?'),
          content: Text('Are you sure you want to delete "${(item as Course).courseName}"?'),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () async {
                final institutionId = await SessionManager.getInstitutionId();
                if (institutionId == null || _departmentId == null) return;
                
                final url = '${ApiConfig.baseUrl}/$institutionId/api/departments/$_departmentId/courses/${item.courseCode}';
                final response = await http.delete(Uri.parse(url));

                if (response.statusCode == 200) {
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  setState(() => _itemsFuture = _fetchData());
                } else {
                  // handle error
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage ${widget.assetType}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No ${widget.assetType.toLowerCase()} found.\nAdd one to get started!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }

          final items = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              String title = '';
              String subtitle = '';

              if (widget.assetType == 'Courses' && item is Course) {
                title = item.courseName;
                subtitle = 'Code: ${item.courseCode} | Students: ${item.studentsEnrolled.length} | Faculty: ${_faculty.firstWhere((f) => f.uid == item.facultyUid, orElse: () => UserModel(uid: '', email: '', displayName: 'N/A', role: '')).displayName}';
              }
              // Add other asset types later

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(subtitle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () => _editItem(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteItem(item),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}

extension on String {
  String get singular {
    if (endsWith('s')) {
      return substring(0, length - 1);
    }
    return this;
  }
}
