import 'package:flutter/material.dart';
import 'package:flutter_application/models/assessment_model.dart';
import 'package:flutter_application/models/submission_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/student_layout.dart';

class StudentAssessmentListScreen extends StatefulWidget {
  final String courseCode;
  const StudentAssessmentListScreen({super.key, required this.courseCode});

  @override
  State<StudentAssessmentListScreen> createState() => _StudentAssessmentListScreenState();
}

class _StudentAssessmentListScreenState extends State<StudentAssessmentListScreen> {
  final ApiService _apiService = ApiService();
  List<AssessmentModel> _assessments = [];
  Map<String, SubmissionModel?> _submissions = {};
  bool _isLoading = true;
  String? _institutionId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (_institutionId == null) return;

    try {
      final assessments = await _apiService.getAssessmentsByCourse(_institutionId!, widget.courseCode);
      
      // Load submissions for each assessment
      Map<String, SubmissionModel?> submissionsMap = {};
      for (var a in assessments) {
        if (a.isSubmissionRequired) {
          try {
            final sub = await _apiService.getMySubmission(_institutionId!, a.id!);
            submissionsMap[a.id!] = sub;
          } catch (e) {
            submissionsMap[a.id!] = null;
          }
        }
      }

      if (mounted) {
        setState(() {
          _assessments = assessments;
          _submissions = submissionsMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading assessments: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: 'Course Evaluations',
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _assessments.length,
            itemBuilder: (context, index) {
              final a = _assessments[index];
              final sub = _submissions[a.id];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${a.type} • Max Marks: ${a.maxMarks}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (a.instructions != null && a.instructions!.isNotEmpty) ...[
                            const Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(a.instructions!),
                            const SizedBox(height: 12),
                          ],
                          if (a.markingScheme != null && a.markingScheme!.isNotEmpty) ...[
                            const Text('Marking Scheme:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(a.markingScheme!),
                            const SizedBox(height: 12),
                          ],
                          const Divider(),
                          if (a.isSubmissionRequired) ...[
                            if (sub == null) 
                              ElevatedButton.icon(
                                onPressed: () => _navigateToSubmit(a),
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Upload Submission'),
                              )
                            else ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(sub.status, style: TextStyle(color: sub.status == 'Graded' ? Colors.green : Colors.orange)),
                                    ],
                                  ),
                                  if (sub.status == 'Graded')
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Marks:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text('${sub.marksObtained} / ${a.maxMarks}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                ],
                              ),
                              if (sub.feedback != null) ...[
                                const SizedBox(height: 8),
                                const Text('Feedback:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(sub.feedback!),
                              ],
                            ],
                          ] else ...[
                            const Text('Submission not required for this assessment type.'),
                          ],
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
    );
  }

  void _navigateToSubmit(AssessmentModel assessment) {
     // Navigation logic to a submission screen
     context.push('/$_institutionId/student/assessment/${assessment.id}/submit');
  }
}
