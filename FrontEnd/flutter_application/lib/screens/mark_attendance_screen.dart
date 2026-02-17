import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';
import '../services/session_manager.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  List<Course> _courses = [];
  List<UserModel> _students = [];
  List<UserModel> _filteredStudents = [];
  Course? _selectedCourse;
  DateTime _selectedDate = DateTime.now();
  Map<String, bool> _attendanceMap = {};
  Map<String, String> _remarksMap = {};
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  String? _institutionId;
  String? _facultyUid;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    _institutionId = await SessionManager.getInstitutionId();
    _facultyUid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (_institutionId == null || _facultyUid == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not retrieve institution or faculty ID.';
        });
      }
      return;
    }
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final loadedCourses = await AttendanceService.getSubjects();
      if (mounted) {
        setState(() {
          _courses = loadedCourses;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } on AttendanceException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading courses: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedCourse == null) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final loadedStudents = await AttendanceService.getStudentsForSubject(_selectedCourse!.courseCode);
      if (mounted) {
        setState(() {
          _students = loadedStudents;
          _filteredStudents = loadedStudents;
          _attendanceMap = {for (var student in loadedStudents) student.uid: false};
          _remarksMap = {for (var student in loadedStudents) student.uid: ''};
          _searchQuery = '';
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } on AttendanceException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading students: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students
            .where((student) =>
                (student.displayName.toLowerCase().contains(query.toLowerCase())) ||
                (student.usn != null && student.usn!.toLowerCase().contains(query.toLowerCase())))
            .toList();
      }
    });
  }

  Future<void> _submitAttendance() async {
    if (_selectedCourse == null) {
      _showErrorSnackbar('Please select a course.');
      return;
    }
    if (_students.isEmpty) {
      _showErrorSnackbar('No students loaded. Please try again.');
      return;
    }
    if (_institutionId == null || _facultyUid == null) {
      _showErrorSnackbar('Missing essential IDs for submission.');
      return;
    }
    // Add null check for departmentId
    if (_selectedCourse!.departmentId == null) {
      _showErrorSnackbar('Selected course is missing a department ID. Cannot mark attendance.');
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      List<AttendanceModel> attendanceRecords = _students.map((student) {
        return AttendanceModel(
          courseCode: _selectedCourse!.courseCode,
          studentUid: student.uid,
          date: dateStr,
          status: _attendanceMap[student.uid] == true ? 'Present' : 'Absent',
          remarks: _remarksMap[student.uid],
          facultyUid: _facultyUid,
          institutionId: _institutionId!,
          departmentId: _selectedCourse!.departmentId!, // Assert non-null after check
        );
      }).toList();

      final success = await AttendanceService.markAttendance(
        courseCode: _selectedCourse!.courseCode,
        institutionId: _institutionId!,
        departmentId: _selectedCourse!.departmentId!, // Assert non-null after check
        facultyUid: _facultyUid!,
        attendanceRecords: attendanceRecords,
      );

      if (success && mounted) {
        _showSuccessSnackbar('Attendance marked successfully!');
        _resetForm();
      }
    } on AttendanceException catch (e) {
      if (mounted) {
        _showErrorSnackbar(e.message);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error marking attendance: ${e.toString()}');
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedCourse = null;
      _students = [];
      _filteredStudents = [];
      _attendanceMap = {};
      _remarksMap = {};
      _selectedDate = DateTime.now();
      _searchQuery = '';
      _isLoading = false;
      _errorMessage = null;
    });
    _loadCourses(); // Reload courses after reset
  }

  void _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && mounted) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mark Attendance',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error Message
                  if (_errorMessage != null) _buildErrorBanner(),

                  // Course Selection
                  _buildSectionTitle('Select Course'),
                  const SizedBox(height: 8),
                  _buildCourseDropdown(),
                  const SizedBox(height: 24),

                  // Date Selection
                  _buildSectionTitle('Select Date'),
                  const SizedBox(height: 8),
                  _buildDatePicker(),
                  const SizedBox(height: 24),

                  // Students List with Search
                  if (_students.isNotEmpty) ...[
                    _buildStudentListHeader(),
                    const SizedBox(height: 12),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                    const SizedBox(height: 12),
                    if (_filteredStudents.isEmpty)
                      _buildEmptySearchState()
                    else
                      _buildStudentsList(),
                  ] else if (_selectedCourse != null) ...[
                    _buildEmptyState('No students found for this course.'),
                  ],

                  const SizedBox(height: 32),

                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade700, size: 18),
            onPressed: () => setState(() => _errorMessage = null),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildCourseDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.white,
      ),
      child: DropdownButton<Course>(
        value: _selectedCourse,
        isExpanded: true,
        underline: const SizedBox(),
        items: _courses
            .map((course) => DropdownMenuItem(
                  value: course,
                  child: SizedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(course.courseName, style: const TextStyle(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                            '${course.courseCode} • ${course.program} • Sem ${course.semester}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
            .toList(),
        onChanged: (course) {
          setState(() => _selectedCourse = course);
          if (course != null) _loadStudents();
        },
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(8.0),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Text(
                  DateFormat('yyyy-MM-dd').format(_selectedDate),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Attendance (${_filteredStudents.length}/${_students.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            border: Border.all(color: Colors.green.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${_attendanceMap.values.where((v) => v).length}/${_students.length} Present',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.white,
      ),
      child: TextField(
        onChanged: _filterStudents,
        decoration: InputDecoration(
          hintText: 'Search by name or USN...',
          hintStyle: TextStyle(color: Colors.grey.shade600),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade600),
                  onPressed: () => _filterStudents(''),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildQuickActionButton(
            'Mark All Present',
            Icons.check_circle,
            Colors.green,
            () {
              setState(() {
                for (var student in _filteredStudents) {
                  _attendanceMap[student.uid] = true;
                }
              });
            },
          ),
          const SizedBox(width: 8),
          _buildQuickActionButton(
            'Mark All Absent',
            Icons.cancel,
            Colors.red,
            () {
              setState(() {
                for (var student in _filteredStudents) {
                  _attendanceMap[student.uid] = false;
                }
              });
            },
          ),
          const SizedBox(width: 8),
          _buildQuickActionButton(
            'Clear Selection',
            Icons.refresh,
            Colors.orange,
            () {
              setState(() {
                for (var student in _students) {
                  _attendanceMap[student.uid] = false;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off, color: Colors.grey.shade600, size: 48),
            const SizedBox(height: 8),
            Text(
              'No students found matching "$_searchQuery"',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        final isPresent = _attendanceMap[student.uid] ?? false;
        final remarks = _remarksMap[student.uid] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isPresent ? Colors.green.shade300 : Colors.grey.shade300,
              width: isPresent ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ExpansionTile(
            title: Row(
              children: [
                Checkbox(
                  value: isPresent,
                  onChanged: (value) {
                    setState(() {
                      _attendanceMap[student.uid] = value ?? false;
                    });
                  },
                  activeColor: Colors.green.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (student.usn != null)
                        Text(
                          student.usn!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
                    border: Border.all(
                      color: isPresent ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPresent ? 'Present' : 'Absent',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Add Remarks (Optional)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.grey.shade50,
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _remarksMap[student.uid] = value;
                          });
                        },
                        controller: TextEditingController(text: remarks),
                        maxLines: 2,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'e.g., Late arrival, Medical leave, etc.',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(10),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, color: Colors.grey.shade600, size: 48),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _students.isEmpty ? null : _submitAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              'Submit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _resetForm,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Text(
              'Reset',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ),
      ],
    );
  }
}