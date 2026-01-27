import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<Subject> subjects = [];
  List<AttendanceSummary> attendanceHistory = [];
  List<AttendanceSummary> filteredHistory = [];
  Subject? selectedSubject;
  bool isLoading = false;
  String? errorMessage;
  
  // Sorting and filtering
  String sortBy = 'percentage_desc'; // percentage_desc, percentage_asc, name_asc, name_desc
  String filterBy = 'all'; // all, excellent (80+), good (70-79), poor (<70)
  bool showOnlyAtRisk = false;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final loadedSubjects = await AttendanceService.getSubjects();
      if (mounted) {
        setState(() {
          subjects = loadedSubjects;
          isLoading = false;
          errorMessage = null;
        });
      }
    } on AttendanceException catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.message;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = AppConstants.errorLoadingSubjects;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAttendanceHistory() async {
    if (selectedSubject == null) return;

    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final history = await AttendanceService.getAttendanceHistory(selectedSubject!.id);
      if (mounted) {
        setState(() {
          attendanceHistory = history;
          _applyFiltersAndSort();
          isLoading = false;
          errorMessage = null;
        });
      }
    } on AttendanceException catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.message;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = AppConstants.errorLoadingHistory;
          isLoading = false;
        });
      }
    }
  }

  void _applyFiltersAndSort() {
    List<AttendanceSummary> result = List.from(attendanceHistory);

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
      filteredHistory = result;
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error Message
                  if (errorMessage != null) _buildErrorBanner(),

                  // Subject Selection
                  _buildSectionTitle(AppStrings.selectSubject),
                  const SizedBox(height: 8),
                  _buildSubjectDropdown(),
                  const SizedBox(height: 24),

                  // Attendance Records
                  if (attendanceHistory.isNotEmpty) ...[
                    _buildRecordsHeader(),
                    const SizedBox(height: 12),
                    _buildFilterAndSortBar(),
                    const SizedBox(height: 12),
                    if (filteredHistory.isEmpty)
                      _buildEmptyState('No records match your filters')
                    else
                      _buildAttendanceList(),
                  ] else if (selectedSubject != null) ...[
                    _buildEmptyState('No attendance records found'),
                  ] else ...[
                    _buildInfoState('Select a subject to view attendance records'),
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
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade700, size: 18),
            onPressed: () => setState(() => errorMessage = null),
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

  Widget _buildSubjectDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        color: Colors.white,
      ),
      child: DropdownButton<Subject>(
        value: selectedSubject,
        isExpanded: true,
        underline: const SizedBox(),
        items: subjects
            .map((subject) => DropdownMenuItem(
                  value: subject,
                  child: SizedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(subject.name, style: const TextStyle(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                            '${subject.code} • ${subject.className}',
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
        onChanged: (subject) {
          setState(() => selectedSubject = subject);
          if (subject != null) _loadAttendanceHistory();
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
            '${attendanceHistory.length} students',
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
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
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
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
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
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
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
      itemCount: filteredHistory.length,
      itemBuilder: (context, index) {
        final summary = filteredHistory[index];
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
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
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
                    const SizedBox(width: 12),
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
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, color: Colors.grey.shade600, size: 48),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600),
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
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
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
