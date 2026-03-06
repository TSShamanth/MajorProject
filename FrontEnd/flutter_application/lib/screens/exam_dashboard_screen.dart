import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/models/exam_model.dart' as app_models;
import '../widgets/admin_layout.dart';

class ExamDashboardScreen extends StatefulWidget {
  const ExamDashboardScreen({super.key});

  @override
  State<ExamDashboardScreen> createState() => _ExamDashboardScreenState();
}

class _ExamDashboardScreenState extends State<ExamDashboardScreen> {
  final ApiService _apiService = ApiService();
  List<app_models.Exam> _exams = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _selectedExamId;
  String? _institutionId;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (_institutionId != null) {
      await _fetchExams();
    }
  }

  Future<void> _fetchExams() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_institutionId != null) {
        final fetchedExams = await _apiService.getExams(_institutionId!);
        if (!mounted) return;
        setState(() {
          _exams = fetchedExams;
          if (_selectedExamId == null && _exams.isNotEmpty) {
            _selectedExamId = _exams.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load exams: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToEditor({String? examId}) {
    if (_institutionId != null) {
      if (examId != null) {
        context.push('/$_institutionId/admin/exam-schedule-editor/$examId');
      } else {
        context.push('/$_institutionId/admin/create-exam');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: 'Examinations',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Exams', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: _isLoading
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
                          Text('Examination Control Panel', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text('Manage schedules, eligibility and hall tickets', style: TextStyle(fontSize: 14, color: textSecondary)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToEditor(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Create New Exam'),
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
                  if (_errorMessage.isNotEmpty)
                    _buildErrorState(textSecondary)
                  else if (_exams.isEmpty)
                    _buildEmptyState(textSecondary)
                  else
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          mainAxisExtent: 220,
                        ),
                        itemCount: _exams.length,
                        itemBuilder: (context, index) => _buildExamCard(_exams[index], textPrimary, textSecondary),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildExamCard(app_models.Exam exam, Color textPrimary, Color textSecondary) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/$_institutionId/admin/exam-management'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.description_rounded, color: Color(0xFF4F46E5), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        exam.name,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.business_rounded, 'Dept: ${exam.departmentId}', textSecondary),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.school_rounded, 'Semester: ${exam.semester}', textSecondary),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.event_note_rounded, '${exam.schedule.length} Subjects Scheduled', textSecondary),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF4F46E5)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: color)),
      ],
    );
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 64, color: textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No Exams Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_errorMessage, style: TextStyle(fontSize: 14, color: textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _fetchExams, child: const Text('Retry')),
        ],
      ),
    );
  }
}
