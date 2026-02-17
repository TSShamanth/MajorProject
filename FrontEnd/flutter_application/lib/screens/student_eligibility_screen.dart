import 'package:flutter/material.dart';
import 'package:flutter_application/models/exam_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';

class StudentEligibilityScreen extends StatefulWidget {
  final String examId;
  const StudentEligibilityScreen({super.key, required this.examId});

  @override
  // ignore: library_private_types_in_public_api
  _StudentEligibilityScreenState createState() => _StudentEligibilityScreenState();
}

class _StudentEligibilityScreenState extends State<StudentEligibilityScreen> {
  late ApiService _apiService;
  Exam? _exam;
  List<UserModel> _eligibleStudents = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchEligibilityData();
  }

  Future<void> _fetchEligibilityData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId != null) {
        // Fetch exam details
        final exam = await _apiService.getExamById(institutionId, widget.examId);
        if (!mounted) return;
        setState(() {
          _exam = exam;
        });

        // Fetch eligible students
        final students = await _apiService.getEligibleStudentsForExam(institutionId, widget.examId);
        if (!mounted) return;
        setState(() {
          _eligibleStudents = students;
        });
      } else {
        _errorMessage = 'Institution ID not found.';
      }
    } catch (e) {
      if (!mounted) return;
      _errorMessage = 'Failed to load data: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Eligibility'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _exam == null
                  ? const Center(child: Text('Exam not found.'))
                  : Builder(builder: (context) {
                      final currentExam = _exam!; // Assign to local non-nullable variable
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Exam: ${currentExam.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text('Department: ${currentExam.departmentId}', style: const TextStyle(fontSize: 16)),
                                Text('Semester: ${currentExam.semester}', style: const TextStyle(fontSize: 16)),
                                const SizedBox(height: 16),
                                const Text('Eligible Students:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _eligibleStudents.isEmpty
                                ? const Center(child: Text('No eligible students found.'))
                                : ListView.builder(
                                    itemCount: _eligibleStudents.length,
                                    itemBuilder: (context, index) {
                                      final student = _eligibleStudents[index];
                                      return ListTile(
                                        title: Text(student.displayName ?? 'N/A'),
                                        subtitle: Text(student.email ?? 'N/A'),
                                      );
                                    },
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: Implement Freeze Candidate List functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Freeze Candidate List functionality not yet implemented.')),
                                );
                              },
                              child: const Text('Freeze Candidate List'),
                            ),
                          ),
                        ],
                      );
                    }),
    );
  }
}
