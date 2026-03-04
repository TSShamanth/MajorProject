import 'package:flutter/material.dart';
import 'package:flutter_application/models/subject_wise_attendance_model.dart';
import 'package:flutter_application/services/attendance_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/constants.dart';
import '../widgets/student_layout.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  List<SubjectWiseAttendance> _subjectWiseAttendance = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _sortBy = 'name_asc';

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

      final List<dynamic> rawAttendance = await AttendanceService.getSubjectWiseAttendance(user.uid);
      final List<SubjectWiseAttendance> attendance = rawAttendance.cast<SubjectWiseAttendance>();

      if (mounted) {
        setState(() {
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
    if (percentage >= AppConstants.attendanceExcellent) return const Color(0xFF10B981);
    if (percentage >= AppConstants.attendanceGood) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _getAttendanceStatus(double percentage) {
    if (percentage >= AppConstants.attendanceExcellent) return 'Excellent';
    if (percentage >= AppConstants.attendanceGood) return 'Good';
    return 'At Risk';
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: 'My Attendance',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Attendance', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadStudentAttendance,
                  color: const Color(0xFF4F46E5),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildSummaryCard(),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Subject-wise Records',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5),
                            ),
                            _buildSortDropdown(),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _subjectWiseAttendance.isEmpty
                            ? _buildEmptyState()
                            : _buildAttendanceList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance Overview',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Monitor your subject-wise presence and overall academic consistency',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButton<String>(
        value: _sortBy,
        underline: const SizedBox(),
        icon: const Icon(Icons.sort_rounded, size: 18, color: Color(0xFF4B5563)),
        items: const [
          DropdownMenuItem(value: 'name_asc', child: Text('Subject (A-Z)', style: TextStyle(fontSize: 13))),
          DropdownMenuItem(value: 'name_desc', child: Text('Subject (Z-A)', style: TextStyle(fontSize: 13))),
          DropdownMenuItem(value: 'percentage_desc', child: Text('Highest %', style: TextStyle(fontSize: 13))),
          DropdownMenuItem(value: 'percentage_asc', child: Text('Lowest %', style: TextStyle(fontSize: 13))),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _sortBy = value);
            _applySorting();
          }
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
          ),
          const SizedBox(height: 20),
          Text(_errorMessage!, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadStudentAttendance,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry Loading'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: Icon(Icons.event_note_outlined, size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text('No records found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[600])),
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF4F46E5), const Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall Consistency', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(
                  '${overallPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildSummaryStat('Present', totalPresent.toString()),
                    const SizedBox(width: 32),
                    _buildSummaryStat('Total', totalClasses.toString()),
                    const SizedBox(width: 32),
                    _buildSummaryStat('Subjects', _subjectWiseAttendance.length.toString()),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 120,
            height: 120,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            child: CircularProgressIndicator(
              value: overallPercentage / 100,
              strokeWidth: 10,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildAttendanceList() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        mainAxisExtent: 220,
      ),
      itemCount: _subjectWiseAttendance.length,
      itemBuilder: (context, index) => _buildAttendanceCard(_subjectWiseAttendance[index]),
    );
  }

  Widget _buildAttendanceCard(SubjectWiseAttendance subject) {
    final percentage = subject.attendancePercentage;
    final color = _getAttendanceColor(percentage);
    final status = _getAttendanceStatus(percentage);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
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
                    Text(subject.courseName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1F2937)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(subject.courseCode, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 0.5)),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
              Text('${subject.attendedClasses}/${subject.totalClasses} Classes', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subject.facultyName,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
