import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application/services/session_manager.dart';

// Mock Data Models
enum ExamStatus { upcoming, ongoing, completed }

class Exam {
  final String title;
  final String dateRange;
  final ExamStatus status;

  Exam({required this.title, required this.dateRange, required this.status});
}

class ExamDashboardScreen extends StatefulWidget {
  const ExamDashboardScreen({super.key});

  @override
  State<ExamDashboardScreen> createState() => _ExamDashboardScreenState();
}

class _ExamDashboardScreenState extends State<ExamDashboardScreen> {
  // Mock Data
  final List<Exam> _exams = [
    Exam(title: 'Mid-Term Examinations - Fall 2024', dateRange: 'Oct 15, 2024 - Oct 25, 2024', status: ExamStatus.upcoming),
    Exam(title: 'Lab Practical Exams - Fall 2024', dateRange: 'Sep 20, 2024 - Sep 28, 2024', status: ExamStatus.ongoing),
    Exam(title: 'Final Examinations - Spring 2024', dateRange: 'May 10, 2024 - May 22, 2024', status: ExamStatus.completed),
    Exam(title: 'Mid-Term Examinations - Spring 2024', dateRange: 'Mar 05, 2024 - Mar 15, 2024', status: ExamStatus.completed),
  ];

  void _navigateToEditor() async {
    final institutionId = await SessionManager.getInstitutionId();
    if (!mounted) return;
    if (institutionId != null) {
      context.go('/$institutionId/admin/exam-schedule-editor');
    }
  }

  @override
  Widget build(BuildContext context) {
    final upcomingExams = _exams.where((e) => e.status == ExamStatus.upcoming).toList();
    final ongoingExams = _exams.where((e) => e.status == ExamStatus.ongoing).toList();
    final completedExams = _exams.where((e) => e.status == ExamStatus.completed).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Examination Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildExamSection('Ongoing Exams', ongoingExams, Colors.orange),
          const SizedBox(height: 24),
          _buildExamSection('Upcoming Exams', upcomingExams, Colors.blue),
          const SizedBox(height: 24),
          _buildExamSection('Past Exams', completedExams, Colors.grey),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToEditor,
        icon: const Icon(Icons.add),
        label: const Text('Schedule New Exam'),
      ),
    );
  }

  Widget _buildExamSection(String title, List<Exam> exams, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (exams.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No exams in this category.'),
          )
        else
          ...exams.map((exam) => _buildExamCard(exam, color)),
      ],
    );
  }

  Widget _buildExamCard(Exam exam, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exam.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.date_range_outlined, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(exam.dateRange, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () {}, child: const Text('View Details')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _navigateToEditor,
                  child: const Text('Manage'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
