import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/models/department_assets_model.dart';
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
  late Future<DepartmentAssets> _assetsFuture;
  String? _departmentId;
  List<UserModel> _faculty = [];
  List<UserModel> _students = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchDepartmentId();
    if (_departmentId != null) {
      setState(() {
        _assetsFuture = _fetchDepartmentAssets();
      });
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

  Future<DepartmentAssets> _fetchDepartmentAssets() async {
    if (_departmentId == null) {
      throw Exception('Department ID not found');
    }
    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) {
      throw Exception('Institution ID not found');
    }

    final apiService = ApiService();
    final coursesFuture = http.get(Uri.parse(
        '${ApiConfig.baseUrl}/$institutionId/api/departments/$_departmentId/courses'));
    final usersFuture = apiService.getUsers(institutionId);

    final responses = await Future.wait([coursesFuture, usersFuture]);

    final coursesResponse = responses[0] as http.Response;
    final users = responses[1] as List<UserModel>;

    if (coursesResponse.statusCode == 200) {
      final List<dynamic> coursesJson = json.decode(coursesResponse.body);
      final courses = coursesJson.map((c) => Course.fromJson(c)).toList();
      final faculty = users.where((user) => user.role == 'faculty').toList();
      final students = users.where((user) => user.role == 'student').toList();

      _faculty = faculty;
      _students = students;

      return DepartmentAssets(
          courses: courses, faculty: faculty, students: students);
    } else {
      throw Exception('Failed to load department assets');
    }
  }
  
  void _addItem() {
    if (widget.assetType == 'Courses') {
      _showAddCourseDialog();
    } else if (widget.assetType == 'Faculty' || widget.assetType == 'Students') {
      _showAddUserDialog();
    }
  }

  void _showAddUserDialog({UserModel? user}) {
    final displayNameController = TextEditingController(text: user?.displayName);
    final emailController = TextEditingController(text: user?.email);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(user == null ? 'Add New ${widget.assetType.singular}' : 'Edit ${widget.assetType.singular}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: displayNameController, decoration: const InputDecoration(labelText: 'Display Name')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              if (user == null) TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            ],
          ),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              child: Text(user == null ? 'Add' : 'Save'),
              onPressed: () async {
                if (displayNameController.text.isNotEmpty && emailController.text.isNotEmpty && (user != null || passwordController.text.isNotEmpty)) {
                  final institutionId = await SessionManager.getInstitutionId();
                  if (institutionId == null) return;
                  
                  final apiService = ApiService();
                  try {
                    if (user == null) {
                      await apiService.createUser(
                        email: emailController.text,
                        password: passwordController.text,
                        displayName: displayNameController.text,
                        role: widget.assetType.toLowerCase().singular,
                        institutionId: institutionId,
                        departmentId: _departmentId,
                      );
                    } else {
                      // Update user logic here
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    setState(() {
                      _assetsFuture = _fetchDepartmentAssets();
                    });
                  } catch (e) {
                    // handle error
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }


  void _showAddCourseDialog({Course? course}) {
    final courseCodeController = TextEditingController(text: course?.courseCode);
    final courseNameController = TextEditingController(text: course?.courseName);
    final programController = TextEditingController(text: course?.program);
    final semesterController = TextEditingController(text: course?.semester);
    final totalClassesController = TextEditingController(text: course?.totalClasses);
    final creditsController = TextEditingController(text: course?.credits.toString() ?? '4');
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
                    TextField(
                      controller: creditsController,
                      decoration: const InputDecoration(labelText: 'Credits (e.g., 4)'),
                      keyboardType: TextInputType.number,
                    ),
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
                        departmentId: _departmentId!,
                        credits: int.tryParse(creditsController.text) ?? 4,
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
                        setState(() => _assetsFuture = _fetchDepartmentAssets());
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

  void _editItem(dynamic item, DepartmentAssets assets) {
    if (widget.assetType == 'Courses' && item is Course) {
      _showAddCourseDialog(course: item);
    } else if ((widget.assetType == 'Faculty' || widget.assetType == 'Students') && item is UserModel) {
      _showCourseAssignmentDialog(user: item, allCourses: assets.courses);
    }
  }

  void _showCourseAssignmentDialog({required UserModel user, required List<Course> allCourses}) {
    List<String> selectedCourseCodes = [];
    if (user.role == 'faculty') {
      selectedCourseCodes = allCourses.where((c) => c.facultyUid == user.uid).map((c) => c.courseCode).toList();
    } else if (user.role == 'student') {
      selectedCourseCodes = allCourses.where((c) => c.studentsEnrolled.contains(user.uid)).map((c) => c.courseCode).toList();
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Assign Courses to ${user.displayName}'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: allCourses.map((course) {
                    return CheckboxListTile(
                      title: Text(course.courseName),
                      value: selectedCourseCodes.contains(course.courseCode),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedCourseCodes.add(course.courseCode);
                          } else {
                            selectedCourseCodes.remove(course.courseCode);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
                ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () async {
                    final institutionId = await SessionManager.getInstitutionId();
                    if (institutionId == null || _departmentId == null) return;

                    final role = user.role == 'faculty' ? 'faculty' : 'student';
                    final url = '${ApiConfig.baseUrl}/$institutionId/api/departments/$_departmentId/$role/${user.uid}/courses';
                    
                    final response = await http.put(
                      Uri.parse(url),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode(selectedCourseCodes),
                    );

                    if (response.statusCode == 200) {
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      setState(() {
                        _assetsFuture = _fetchDepartmentAssets();
                      });
                    } else {
                      // Handle error
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

  void _deleteItem(dynamic item) {
    String itemName = '';
    String actionText = 'Delete';
    if (item is Course) {
      itemName = item.courseName;
    } else if (item is UserModel) {
      itemName = item.displayName;
      actionText = 'Unassign';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$actionText ${widget.assetType.singular}?'),
          content: Text('Are you sure you want to $actionText "$itemName"?'),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(actionText),
              onPressed: () async {
                final institutionId = await SessionManager.getInstitutionId();
                if (institutionId == null) return;
                
                try {
                  if (item is Course) {
                    final url = '${ApiConfig.baseUrl}/$institutionId/api/departments/$_departmentId/courses/${item.courseCode}';
                    await http.delete(Uri.parse(url));
                  } else if (item is UserModel) {
                    if (widget.assetType == 'Faculty') {
                      final url = '${ApiConfig.baseUrl}/$institutionId/api/departments/$_departmentId/faculty/${item.uid}';
                      await http.delete(Uri.parse(url));
                    } else if (widget.assetType == 'Students') {
                      final url = '${ApiConfig.baseUrl}/$institutionId/api/departments/$_departmentId/student/${item.uid}';
                      await http.delete(Uri.parse(url));
                    }
                  }

                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  setState(() {
                    _assetsFuture = _fetchDepartmentAssets();
                  });
                } catch (e) {
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
      body: FutureBuilder<DepartmentAssets>(
        future: _assetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(
              child: Text(
                'No ${widget.assetType.toLowerCase()} found.\nAdd one to get started!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }

          final assets = snapshot.data!;
          final items = widget.assetType == 'Courses' ? assets.courses : (widget.assetType == 'Faculty' ? assets.faculty : assets.students);

          if (items.isEmpty) {
             return Center(
              child: Text(
                'No ${widget.assetType.toLowerCase()} found.\nAdd one to get started!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              String title = '';
              String subtitle = '';

              if (widget.assetType == 'Courses' && item is Course) {
                title = item.courseName;
                final facultyName = assets.faculty.firstWhere((f) => f.uid == item.facultyUid, orElse: () => UserModel(uid: '', email: '', displayName: 'N/A', role: '')).displayName;
                subtitle = 'Code: ${item.courseCode} | Students: ${item.studentsEnrolled.length} | Faculty: $facultyName';
              } else if (widget.assetType == 'Faculty' && item is UserModel) {
                title = item.displayName;
                subtitle = _getUserCourseInfo(item, assets.courses);
              } else if (widget.assetType == 'Students' && item is UserModel) {
                title = item.displayName;
                subtitle = _getUserCourseInfo(item, assets.courses);
              }

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
                        onPressed: () => _editItem(item, assets),
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

  String _getUserCourseInfo(UserModel user, List<Course> courses) {
    List<String> userCourseCodes;
    if (user.role == 'faculty') {
      userCourseCodes = user.assignedCourseCodes ?? [];
    } else if (user.role == 'student') {
      userCourseCodes = user.enrolledCourseCodes ?? [];
    } else {
      userCourseCodes = [];
    }

    if (userCourseCodes.isEmpty) {
      return 'No courses assigned/enrolled.';
    }

    final assignedCourses = courses.where((c) => userCourseCodes.contains(c.courseCode)).toList();

    if (assignedCourses.isEmpty) {
      return 'No courses assigned/enrolled.';
    }

    final courseCodes = assignedCourses.map((c) => c.courseCode).join(', ');

    if (user.role == 'faculty') {
      final totalClasses = assignedCourses.fold<int>(0, (prev, course) => prev + (int.tryParse(course.totalClasses) ?? 0));
      return 'Courses: $courseCodes | Total Classes: $totalClasses';
    } else if (user.role == 'student') {
      return 'Courses: $courseCodes';
    }
    return '';
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
