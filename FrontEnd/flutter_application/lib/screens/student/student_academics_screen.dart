import 'package:flutter/material.dart';
import 'package:flutter_application/models/marks_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/student_layout.dart';

class StudentAcademicsScreen extends StatefulWidget {
  const StudentAcademicsScreen({super.key});

  @override
  State<StudentAcademicsScreen> createState() => _StudentAcademicsScreenState();
}

class _StudentAcademicsScreenState extends State<StudentAcademicsScreen> {
  final ApiService _apiService = ApiService();
  String? _institutionId;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  
  List<MarksModel> _allMarks = [];
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    _institutionId = GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'];
    
    final institutionId = _institutionId;
    final uid = _uid;
    
    if (institutionId == null || uid == null) return;

    try {
      final results = await Future.wait([
        _apiService.getMarksByStudent(institutionId, uid),
        _apiService.getAcademicSummary(institutionId, uid),
      ]);

      if (mounted) {
        setState(() {
          _allMarks = results[0] as List<MarksModel>;
          _summary = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading academic records: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: 'Academic Records',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Academics', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchData,
            color: const Color(0xFF4F46E5),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(),
                  const SizedBox(height: 24),
                  _buildSummaryGrid(),
                  const SizedBox(height: 32),
                  const Text(
                    'Performance History',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.w800, 
                      color: Color(0xFF1F2937),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMarksList(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Academic Records',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Detailed overview of your marks and performance indicators',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            _buildStatCard('Assignments', '${_summary?['assignmentsCompleted'] ?? 0}/${_summary?['assignmentsTotal'] ?? 5}', (_summary?['assignmentsPercentage'] ?? 0.0) / 100, const Color(0xFF10B981), Icons.assignment_turned_in_rounded),
            _buildStatCard('Internal Tests', '${_summary?['testsAttempted'] ?? 0}/${_summary?['testsTotal'] ?? 3}', (_summary?['testsPercentage'] ?? 0.0) / 100, const Color(0xFF4F46E5), Icons.quiz_rounded),
            _buildStatCard('Project Work', '${_summary?['projectsSubmitted'] ?? 0}/${_summary?['projectsTotal'] ?? 1}', (_summary?['projectsPercentage'] ?? 0.0) / 100, const Color(0xFFF59E0B), Icons.account_tree_rounded),
            _buildStatCard('Overall Score', '${(_summary?['averageExamScore'] ?? 0.0).toStringAsFixed(1)}%', (_summary?['examsPercentage'] ?? 0.0) / 100, const Color(0xFF8B5CF6), Icons.analytics_rounded),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, double progress, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarksList() {
    if (_allMarks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Icon(Icons.folder_open_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No academic records found.',
              style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    final sortedMarks = List<MarksModel>.from(_allMarks)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedMarks.length,
      itemBuilder: (context, index) {
        final mark = sortedMarks[index];
        final percentage = (mark.obtainedMarks / mark.totalMarks * 100);
        final typeColor = _getColorForType(mark.type);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getIconForType(mark.type), color: typeColor, size: 24),
              ),
              title: Text(
                mark.title,
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        mark.courseCode,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mark.type,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${mark.obtainedMarks}/${mark.totalMarks}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1F2937), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (percentage >= 40 ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: percentage >= 40 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'Assignment': return const Color(0xFF10B981);
      case 'Internal Test': return const Color(0xFF4F46E5);
      case 'Project': return const Color(0xFFF59E0B);
      case 'Final Exam': return const Color(0xFF8B5CF6);
      default: return const Color(0xFF6B7280);
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Assignment': return Icons.assignment_outlined;
      case 'Internal Test': return Icons.quiz_outlined;
      case 'Project': return Icons.account_tree_outlined;
      case 'Final Exam': return Icons.school_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }
}
