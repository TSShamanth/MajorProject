import 'package:flutter/material.dart';
import 'package:flutter_application/models/exam_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import '../widgets/faculty_layout.dart';

class FacultyExamTimetableScreen extends StatefulWidget {
  const FacultyExamTimetableScreen({super.key});

  @override
  FacultyExamTimetableScreenState createState() => FacultyExamTimetableScreenState();
}

class FacultyExamTimetableScreenState extends State<FacultyExamTimetableScreen> {
  late ApiService _apiService;
  List<Exam> _exams = [];
  bool _isLoading = true;
  String? _institutionId;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      _institutionId = await SessionManager.getInstitutionId();
      if (_institutionId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final results = await Future.wait([
        _apiService.getMe(_institutionId!),
        _apiService.getExams(_institutionId!),
      ]);

      final user = results[0] as UserModel;
      final allExams = results[1] as List<Exam>;

      final filteredExams = allExams.where((exam) {
        return exam.departmentId == user.departmentId;
      }).toList();

      if (mounted) {
        setState(() {
          _exams = filteredExams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);

    return FacultyLayout(
      title: 'Exam Schedule',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Exams', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
      ],
      child: Padding(
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
                    Text(
                      'Exam Timetables',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View published exam schedules for your department',
                      style: TextStyle(fontSize: 14, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _fetchData,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _exams.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _exams.length,
                          itemBuilder: (context, index) {
                            return _buildExamCard(_exams[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_rounded, size: 64, color: _isDarkMode ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'No exam timetables found.',
            style: TextStyle(fontSize: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'Departmental schedules will appear here once published.',
            style: TextStyle(fontSize: 13, color: _isDarkMode ? Colors.grey[500] : Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(Exam exam) {
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_institutionId != null) {
              context.push('/$_institutionId/faculty/timetable/${exam.id}');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.assignment_rounded, color: Color(0xFF4F46E5), size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.name,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.school_outlined, size: 14, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            'Semester ${exam.semester}',
                            style: TextStyle(fontSize: 13, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: _isDarkMode ? Colors.grey[600] : Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
