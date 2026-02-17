import 'package:flutter/material.dart';
import 'package:flutter_application/models/course_model.dart';
import 'package:flutter_application/models/department_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:intl/intl.dart';

class CreateExamScreen extends StatefulWidget {
  const CreateExamScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CreateExamScreenState createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _examNameController = TextEditingController();
  final _examDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _durationController = TextEditingController();
  String? _selectedDepartment;
  String? _selectedSemester;
  List<String> _selectedSubjects = [];

  late ApiService _apiService;
  List<Department> _departments = [];
  List<Course> _courses = [];
  bool _isLoadingDepartments = false;
  bool _isLoadingCourses = false;

  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchDepartments();
  }

  @override
  void dispose() {
    _examNameController.dispose();
    _examDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _fetchDepartments() async {
    if (!mounted) return; // Ensure widget is still mounted
    setState(() {
      _isLoadingDepartments = true;
    });
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId != null) {
        final departments = await _apiService.getDepartments(institutionId);
        if (!mounted) return; // Ensure widget is still mounted before setState
        setState(() {
          _departments = departments;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) { // Ensure widget is still mounted before setState
        setState(() {
          _isLoadingDepartments = false;
        });
      }
    }
  }

  Future<void> _fetchCourses(String departmentId) async {
    if (!mounted) return; // Ensure widget is still mounted
    setState(() {
      _isLoadingCourses = true;
      _courses = [];
      _selectedSubjects = [];
    });
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId != null) {
        final courses = await _apiService.getCourses(institutionId, departmentId);
        if (!mounted) return; // Ensure widget is still mounted before setState
        setState(() {
          _courses = courses;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) { // Ensure widget is still mounted before setState
        setState(() {
          _isLoadingCourses = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _examDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, {required bool isStartTime}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_selectedStartTime ?? TimeOfDay.now())
          : (_selectedEndTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = picked;
          _startTimeController.text = picked.format(context);
        } else {
          _selectedEndTime = picked;
          _endTimeController.text = picked.format(context);
        }
        _calculateDuration();
      });
    }
  }

  void _calculateDuration() {
    if (_selectedStartTime != null && _selectedEndTime != null) {
      final now = DateTime.now();
      final startDateTime = DateTime(
          now.year, now.month, now.day, _selectedStartTime!.hour, _selectedStartTime!.minute);
      final endDateTime = DateTime(
          now.year, now.month, now.day, _selectedEndTime!.hour, _selectedEndTime!.minute);

      // Handle cases where end time is on the next day
      Duration duration;
      if (endDateTime.isBefore(startDateTime)) {
        duration = endDateTime.add(const Duration(days: 1)).difference(startDateTime);
      } else {
        duration = endDateTime.difference(startDateTime);
      }

      _durationController.text = '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      _durationController.text = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Exam'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _examNameController,
                decoration: const InputDecoration(
                  labelText: 'Exam Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an exam name';
                  }
                  return null;
                },
              ),
              InkWell(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _examDateController,
                    decoration: const InputDecoration(
                      labelText: 'Exam Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) {
                      if (_selectedDate == null) {
                        return 'Please select an exam date';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              InkWell(
                onTap: () => _selectTime(context, isStartTime: true),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _startTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Start Time',
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    validator: (value) {
                      if (_selectedStartTime == null) {
                        return 'Please select a start time';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              InkWell(
                onTap: () => _selectTime(context, isStartTime: false),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _endTimeController,
                    decoration: const InputDecoration(
                      labelText: 'End Time',
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    validator: (value) {
                      if (_selectedEndTime == null) {
                        return 'Please select an end time';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                ),
                readOnly: true, // Duration is calculated automatically
                validator: (value) {
                  if (_selectedStartTime == null || _selectedEndTime == null) {
                    return 'Please select start and end times';
                  }
                  // Basic validation for duration logic if needed
                  return null;
                },
              ),
              _isLoadingDepartments
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<String>(
                      value: _selectedDepartment,
                      hint: const Text('Select Department'),
                      onChanged: (value) {
                        setState(() {
                          _selectedDepartment = value;
                          _fetchCourses(value!);
                        });
                      },
                      items: _departments.map((department) {
                        return DropdownMenuItem(
                          value: department.id,
                          child: Text(department.name),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a department';
                        }
                        return null;
                      },
                    ),
              DropdownButtonFormField<String>(
                value: _selectedSemester,
                hint: const Text('Select Semester'),
                onChanged: (value) {
                  setState(() {
                    _selectedSemester = value;
                  });
                },
                items: ['1', '2', '3', '4', '5', '6', '7', '8'].map((semester) {
                  return DropdownMenuItem(
                    value: semester,
                    child: Text(semester),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a semester';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _isLoadingCourses
                  ? const CircularProgressIndicator()
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _courses.length,
                        itemBuilder: (context, index) {
                          final course = _courses[index];
                          return CheckboxListTile(
                            title: Text(course.courseName),
                            value: _selectedSubjects.contains(course.courseCode),
                            onChanged: (value) {
                              setState(() {
                                if (value!) {
                                  _selectedSubjects.add(course.courseCode);
                                } else {
                                  _selectedSubjects.remove(course.courseCode);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _createExam();
                  }
                },
                child: const Text('Create Exam'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createExam() async {
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId != null) {
        final examData = {
          'name': _examNameController.text,
          'departmentId': _selectedDepartment,
          'semester': _selectedSemester,
          'subjects': _selectedSubjects,
          'examDate': _examDateController.text,
          'startTime': _startTimeController.text,
          'endTime': _endTimeController.text,
          'duration': _durationController.text,
        };
        final response = await _apiService.createExam(institutionId, examData);
        if (!mounted) return; // Add mounted check
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exam created successfully')),
          );
          // Removed Navigator.pop(context) as requested. User stays on screen.
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create exam: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return; // Add mounted check
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }
}
