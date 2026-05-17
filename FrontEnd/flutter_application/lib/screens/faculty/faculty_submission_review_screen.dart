import 'package:flutter/material.dart';
import 'package:flutter_application/models/submission_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/faculty_layout.dart';

class FacultySubmissionReviewScreen extends StatefulWidget {
  final String assessmentId;
  const FacultySubmissionReviewScreen({super.key, required this.assessmentId});

  @override
  State<FacultySubmissionReviewScreen> createState() => _FacultySubmissionReviewScreenState();
}

class _FacultySubmissionReviewScreenState extends State<FacultySubmissionReviewScreen> {
  final ApiService _apiService = ApiService();
  List<SubmissionModel> _submissions = [];
  bool _isLoading = true;
  String? _institutionId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _institutionId = GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'];
    if (_institutionId == null) return;

    try {
      final subs = await _apiService.getSubmissionsByAssessment(_institutionId!, widget.assessmentId);
      if (mounted) {
        setState(() {
          _submissions = subs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading submissions: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showGradeDialog(SubmissionModel submission) {
    final marksController = TextEditingController(text: submission.marksObtained.toString());
    final feedbackController = TextEditingController(text: submission.feedback ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grade: ${submission.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: marksController,
              decoration: const InputDecoration(labelText: 'Marks Obtained'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(labelText: 'Feedback'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.gradeSubmission(
                  _institutionId!,
                  submission.id!,
                  double.parse(marksController.text),
                  feedbackController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Submit Grade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FacultyLayout(
      title: 'Submission Review',
      child: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _submissions.isEmpty
          ? const Center(child: Text('No submissions yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _submissions.length,
              itemBuilder: (context, index) {
                final s = _submissions[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(s.studentName),
                    subtitle: Text('Submitted: ${DateTime.fromMillisecondsSinceEpoch(s.submittedAt).toString().substring(0, 16)}'),
                    trailing: s.status == 'Graded' 
                      ? Text('${s.marksObtained} Marks', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
                      : const Text('Pending', style: TextStyle(color: Colors.orange)),
                    onTap: () => _showGradeDialog(s),
                  ),
                );
              },
            ),
    );
  }
}
