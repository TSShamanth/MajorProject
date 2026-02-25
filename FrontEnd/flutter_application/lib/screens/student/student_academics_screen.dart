import 'package:flutter/material.dart';
import 'package:flutter_application/models/marks_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Performance'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent Marks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildMarksList(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Assignments', '${_summary?['assignmentsCompleted'] ?? 0}/${_summary?['assignmentsTotal'] ?? 5}', (_summary?['assignmentsPercentage'] ?? 0.0) / 100, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Tests', '${_summary?['testsAttempted'] ?? 0}/${_summary?['testsTotal'] ?? 3}', (_summary?['testsPercentage'] ?? 0.0) / 100, Colors.blue)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Projects', '${_summary?['projectsSubmitted'] ?? 0}/${_summary?['projectsTotal'] ?? 1}', (_summary?['projectsPercentage'] ?? 0.0) / 100, Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Exam Avg', '${(_summary?['averageExamScore'] ?? 0.0).toStringAsFixed(1)}%', (_summary?['examsPercentage'] ?? 0.0) / 100, Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, double progress, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarksList() {
    if (_allMarks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No academic records found.'),
        ),
      );
    }

    // Sort marks by timestamp descending
    final sortedMarks = List<MarksModel>.from(_allMarks)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedMarks.length,
      itemBuilder: (context, index) {
        final mark = sortedMarks[index];
        final percentage = (mark.obtainedMarks / mark.totalMarks * 100);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getColorForType(mark.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getIconForType(mark.type), color: _getColorForType(mark.type)),
            ),
            title: Text(mark.title),
            subtitle: Text('${mark.courseCode} • ${mark.type}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${mark.obtainedMarks}/${mark.totalMarks}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: percentage >= 40 ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'Assignment': return Colors.green;
      case 'Internal Test': return Colors.blue;
      case 'Project': return Colors.orange;
      case 'Final Exam': return Colors.purple;
      default: return Colors.grey;
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
