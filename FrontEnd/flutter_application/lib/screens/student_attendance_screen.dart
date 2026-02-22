import 'package:flutter/material.dart';
import 'package:flutter_application/models/subject_wise_attendance_model.dart';
import 'package:flutter_application/services/attendance_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/constants.dart'; // Import AppConstants

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  List<SubjectWiseAttendance> _subjectWiseAttendance = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _studentName = 'Student'; // Will update from UserModel
  String? _sortBy = 'name_asc'; // name_asc, name_desc, percentage_desc, percentage_asc

  @override
  void initState() {
    super.initState();
    _loadStudentAttendance();
  }

  Future<void> _loadStudentAttendance() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Please log in to view your attendance';
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch subject-wise attendance records
      final List<dynamic> rawAttendance = await AttendanceService.getSubjectWiseAttendance(user.uid);
      final List<SubjectWiseAttendance> attendance = rawAttendance.cast<SubjectWiseAttendance>();


      if (mounted) {
        setState(() {
          _studentName = user.displayName ?? 'Student'; // Assuming displayName is available
          _subjectWiseAttendance = attendance;
          _isLoading = false;
          _applySorting();
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load attendance: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _applySorting() {
    if (_sortBy == null) return;

    final sorted = List<SubjectWiseAttendance>.from(_subjectWiseAttendance);

    switch (_sortBy) {
      case 'name_asc':
        sorted.sort((a, b) => a.courseName.compareTo(b.courseName));
        break;
      case 'name_desc':
        sorted.sort((a, b) => b.courseName.compareTo(a.courseName));
        break;
      case 'percentage_desc':
        sorted.sort((a, b) => b.attendancePercentage.compareTo(a.attendancePercentage));
        break;
      case 'percentage_asc':
        sorted.sort((a, b) => a.attendancePercentage.compareTo(b.attendancePercentage));
        break;
    }

    if (mounted) {
      setState(() {
        _subjectWiseAttendance = sorted;
      });
    }
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= AppConstants.attendanceExcellent) return Colors.green;
    if (percentage >= AppConstants.attendanceGood) return Colors.amber;
    return Colors.red;
  }

  String _getAttendanceStatus(double percentage) {
    if (percentage >= AppConstants.attendanceExcellent) return 'Excellent';
    if (percentage >= AppConstants.attendanceGood) return 'Good';
    return 'At Risk'; // Simplified for now
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Attendance - $_studentName'),
        elevation: 0,
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _subjectWiseAttendance.isEmpty
                  ? _buildEmptyState()
                  : _buildAttendanceList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadStudentAttendance,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No attendance records found',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Your attendance will appear here',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with summary
            _buildSummaryCard(),
            const SizedBox(height: 24),

            // Sort options
            _buildSortBar(),
            const SizedBox(height: 16),

            // Subject attendance cards
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _subjectWiseAttendance.length,
              itemBuilder: (context, index) {
                final subject = _subjectWiseAttendance[index];
                final percentage = subject.attendancePercentage;
                final isAtRisk = percentage < 75; // Using a fixed threshold for 'at risk' for now

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isAtRisk ? Colors.orange.shade300 : Colors.grey.shade300,
                        width: isAtRisk ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subject name and status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subject.courseName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      subject.courseCode,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (isAtRisk)
                                    Icon(Icons.warning_rounded, color: Colors.orange.shade600, size: 20),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getAttendanceColor(percentage).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _getAttendanceStatus(percentage),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _getAttendanceColor(percentage),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Faculty Name
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'Marked by: ${subject.facultyName}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Attendance percentage
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Attendance',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _getAttendanceColor(percentage),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(_getAttendanceColor(percentage)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Classes info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoChip(
                                '${subject.attendedClasses} Attended',
                                Colors.green,
                              ),
                              _buildInfoChip(
                                '${subject.totalClasses - subject.attendedClasses} Missed',
                                Colors.red,
                              ),
                              _buildInfoChip(
                                '${subject.totalClasses} Total',
                                Colors.blue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalClasses = _subjectWiseAttendance.fold<int>(0, (sum, s) => sum + s.totalClasses);
    final totalPresent = _subjectWiseAttendance.fold<int>(0, (sum, s) => sum + s.attendedClasses);
    final overallPercentage = totalClasses > 0 ? (totalPresent / totalClasses) * 100 : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.indigo.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Attendance',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 12),
          Text(
            '${overallPercentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attended',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalPresent',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Classes',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalClasses',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subjects',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_subjectWiseAttendance.length}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.sort, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: _sortBy,
              isExpanded: true,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(
                  value: 'name_asc',
                  child: Text('Subject (A-Z)', style: TextStyle(fontSize: 13)),
                ),
                DropdownMenuItem(
                  value: 'name_desc',
                  child: Text('Subject (Z-A)', style: TextStyle(fontSize: 13)),
                ),
                DropdownMenuItem(
                  value: 'percentage_desc',
                  child: Text('Highest Attendance', style: TextStyle(fontSize: 13)),
                ),
                DropdownMenuItem(
                  value: 'percentage_asc',
                  child: Text('Lowest Attendance', style: TextStyle(fontSize: 13)),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortBy = value);
                  _applySorting();
                }
              },
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
              dropdownColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}