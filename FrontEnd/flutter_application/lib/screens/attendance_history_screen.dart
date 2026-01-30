import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../config/constants.dart';

import '../services/attendance_service.dart';
import '../models/course_model.dart';
import '../models/attendance_model.dart';

import '../services/session_manager.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<Course> _courses = [];
  List<AttendanceSummary> _attendanceHistory = [];
  List<AttendanceSummary> _filteredHistory = [];
  Course? _selectedCourse;
  bool _isLoading = false;
  String? _errorMessage;
  
  String? _institutionId;
  String? _facultyUid; // To fetch faculty-specific courses

  // Sorting and filtering
  String sortBy = 'percentage_desc'; // percentage_desc, percentage_asc, name_asc, name_desc
  String filterBy = 'all'; // all, excellent (80+), good (70-79), poor (<70)
  bool showOnlyAtRisk = false;

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
      final loadedCourses = await AttendanceService.getSubjects(); // This now returns List<Course>
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

  Future<void> _loadAttendanceHistory() async {
    if (_selectedCourse == null) return;
    if (_institutionId == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Missing institution ID for attendance history.';
        });
      }
      return;
    }
    // Add null check for departmentId
    if (_selectedCourse!.departmentId == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Selected course is missing a department ID. Cannot fetch attendance history.';
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final List<AttendanceModel> rawHistory = await AttendanceService.getAttendanceHistory(
        _institutionId!,
        _selectedCourse!.departmentId,
        _selectedCourse!.courseCode,
      );

      // Aggregate raw attendance into AttendanceSummary
      Map<String, Map<String, dynamic>> tempAggregated = {};

      for (var record in rawHistory) {
        if (!tempAggregated.containsKey(record.studentUid)) {
          // For now, student name is a placeholder. In a real app, you'd fetch student details.
          tempAggregated[record.studentUid] = {
            'studentId': record.studentUid,
            'studentName': 'Student ${record.studentUid}', 
            'totalClasses': 0,
            'classesPresent': 0,
            'attendancePercentage': 0.0,
          };
        }

        tempAggregated[record.studentUid]!['totalClasses']++;
        if (record.status == 'Present') {
          tempAggregated[record.studentUid]!['classesPresent']++;
        }
      }

      List<AttendanceSummary> aggregatedSummaries = tempAggregated.values.map((data) {
        final total = data['totalClasses'] as int;
        final present = data['classesPresent'] as int;
        final percentage = total > 0 ? (present / total) * 100 : 0.0;
        return AttendanceSummary(
          studentId: data['studentId'],
          studentName: data['studentName'],
          totalClasses: total,
          classesPresent: present,
          attendancePercentage: percentage,
        );
      }).toList();


      if (mounted) {
        setState(() {
          _attendanceHistory = aggregatedSummaries;
          _applyFiltersAndSort();
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
          _errorMessage = 'Error loading attendance history: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFiltersAndSort() {
    List<AttendanceSummary> result = List.from(_attendanceHistory);

    // Apply filter
    if (filterBy == 'excellent') {
      result = result.where((s) => s.attendancePercentage >= AppConstants.attendanceExcellent).toList();
    } else if (filterBy == 'good') {
      result = result.where((s) => s.attendancePercentage >= AppConstants.attendanceGood && s.attendancePercentage < AppConstants.attendanceExcellent).toList();
    } else if (filterBy == 'poor') {
      result = result.where((s) => s.attendancePercentage < AppConstants.attendanceGood).toList();
    }

    if (showOnlyAtRisk) {
      result = result.where((s) => s.attendancePercentage < 75).toList();
    }

    // Apply sorting
    if (sortBy == 'percentage_desc') {
      result.sort((a, b) => b.attendancePercentage.compareTo(a.attendancePercentage));
    } else if (sortBy == 'percentage_asc') {
      result.sort((a, b) => a.attendancePercentage.compareTo(b.attendancePercentage));
    } else if (sortBy == 'name_asc') {
      result.sort((a, b) => a.studentName.compareTo(b.studentName));
    } else if (sortBy == 'name_desc') {
      result.sort((a, b) => b.studentName.compareTo(a.studentName));
    }

    setState(() {
      _filteredHistory = result;
    });
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= AppConstants.attendanceExcellent) return Colors.green;
    if (percentage >= AppConstants.attendanceGood) return Colors.amber;
    return Colors.red;
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
          AppStrings.attendanceHistory,
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

                  // Attendance Records
                  if (_attendanceHistory.isNotEmpty) ...[
                    _buildRecordsHeader(),
                    const SizedBox(height: 12),
                    _buildFilterAndSortBar(),
                    const SizedBox(height: 12),
                    if (_filteredHistory.isEmpty)
                      _buildEmptyState('No records match your filters')
                    else
                      _buildAttendanceList(),
                  ] else if (_selectedCourse != null) ...[
                    _buildEmptyState('No attendance records found for this course.'),
                  ] else ...[
                    _buildInfoState('Select a course to view attendance records'),
                  ],
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
          if (course != null) _loadAttendanceHistory();
        },
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildRecordsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Student Records',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${_attendanceHistory.length} students',
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterAndSortBar() {
    return Column(
      children: [
        // Sort Dropdown
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8.0),
            color: Colors.white,
          ),
          child: DropdownButton<String>(
            value: sortBy,
            isExpanded: true,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'percentage_desc', child: Text('Sort: Highest Attendance ↓')),
              DropdownMenuItem(value: 'percentage_asc', child: Text('Sort: Lowest Attendance ↑')),
              DropdownMenuItem(value: 'name_asc', child: Text('Sort: Name (A-Z)')),
              DropdownMenuItem(value: 'name_desc', child: Text('Sort: Name (Z-A)')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  sortBy = value;
                  _applyFiltersAndSort();
                });
              }
            },
            padding: const EdgeInsets.all(8),
          ),
        ),
        const SizedBox(height: 8),
        // Filter and At-Risk Toggle
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.white,
                ),
                child: DropdownButton<String>(
                  value: filterBy,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Students')),
                    DropdownMenuItem(value: 'excellent', child: Text('Excellent (80%+)')),
                    DropdownMenuItem(value: 'good', child: Text('Good (70-79%)')),
                    DropdownMenuItem(value: 'poor', child: Text('Poor (<70%)')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        filterBy = value;
                        _applyFiltersAndSort();
                      });
                    }
                  },
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: showOnlyAtRisk ? Colors.red.shade300 : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8.0),
                color: showOnlyAtRisk ? Colors.red.shade50 : Colors.white,
              ),
              child: Tooltip(
                message: 'Show students with attendance < 75%',
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      showOnlyAtRisk = !showOnlyAtRisk;
                      _applyFiltersAndSort();
                    });
                  },
                  icon: Icon(
                    Icons.warning_amber_rounded,
                    color: showOnlyAtRisk ? Colors.red.shade600 : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredHistory.length,
      itemBuilder: (context, index) {
        final summary = _filteredHistory[index];
        final color = _getAttendanceColor(summary.attendancePercentage);
        final isAtRisk = summary.attendancePercentage < 75;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isAtRisk ? Colors.orange.shade300 : Colors.grey.shade300,
              width: isAtRisk ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  summary.studentName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isAtRisk)
                                Tooltip(
                                  message: 'At risk of not meeting attendance requirement',
                                  child: Icon(Icons.warning_rounded, color: Colors.orange.shade600, size: 16),
                                ),
                            ],
                          ),
                          Text(
                            summary.studentId,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        border: Border.all(color: color),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${summary.attendancePercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: summary.attendancePercentage / 100,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${summary.classesPresent}/${summary.totalClasses}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
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

  Widget _buildInfoState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade600, size: 32),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.blue.shade600),
            ),
          ],
        ),
      ),
    );
  }
}