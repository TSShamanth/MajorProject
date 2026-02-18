import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/models/exam_model.dart' as app_models; // Alias to avoid conflict

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
  String? _selectedExamId; // New state variable for dropdown selection

  @override
  void initState() {
    super.initState();
    _fetchExams().then((_) {
      if (_exams.isNotEmpty) {
        setState(() {
          _selectedExamId = _exams.first.id; // Set first exam as default selected
        });
      }
    });
  }

  Future<void> _fetchExams() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId != null) {
        final fetchedExams = await _apiService.getExams(institutionId);
        if (!mounted) return;
        setState(() {
          _exams = fetchedExams;
          // After fetching, if _selectedExamId is null, try to set a default
          if (_selectedExamId == null && _exams.isNotEmpty) {
            _selectedExamId = _exams.first.id;
          }
        });
      } else {
        _errorMessage = 'Institution ID not found.';
      }
    } catch (e) {
      if (!mounted) return;
      _errorMessage = 'Failed to load exams: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToEditor({String? examId}) async {
    final institutionId = await SessionManager.getInstitutionId();
    if (!mounted) return;
    if (institutionId != null) {
      if (examId != null) {
        context.go('/$institutionId/admin/exam-schedule-editor/$examId');
      } else {
        context.go('/$institutionId/admin/exam-schedule-editor');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Examination Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar),
            tooltip: 'Manage Selected Exam Schedule',
            onPressed: _selectedExamId == null
                ? null // Disable button if no exam is selected
                : () => _navigateToEditor(examId: _selectedExamId!),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _exams.isEmpty
                  ? const Center(child: Text('No exams found.'))
                  : Column( // Changed from ListView to Column
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: DropdownButtonFormField<String>(
                            value: _selectedExamId,
                            decoration: const InputDecoration(
                              labelText: 'Select Exam to Manage Schedule',
                              border: OutlineInputBorder(),
                            ),
                            items: _exams.map((exam) {
                              return DropdownMenuItem<String>(
                                value: exam.id,
                                child: Text(exam.name),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedExamId = newValue;
                              });
                            },
                          ),
                        ),
                        Expanded( // Wrap the exam list in Expanded
                          child: ListView(
                            padding: const EdgeInsets.all(16.0),
                            children: [
                              _buildExamSection('All Exams', _exams),
                            ],
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEditor(), // Navigate to create new exam
        icon: const Icon(Icons.add),
        label: const Text('Create New Exam'),
      ),
    );
  }

  Widget _buildExamSection(String title, List<app_models.Exam> exams) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...exams.map((exam) => _buildExamCard(exam)),
      ],
    );
  }

  Widget _buildExamCard(app_models.Exam exam) {
    String scheduleSummary = 'Not Scheduled';
    if (exam.schedule.isNotEmpty) {
      scheduleSummary = '${exam.schedule.length} subjects scheduled';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).primaryColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exam.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.school_outlined, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text('Dept: ${exam.departmentId}', style: TextStyle(color: Colors.grey[700])),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.book_outlined, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text('Semester: ${exam.semester}', style: TextStyle(color: Colors.grey[700])),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(scheduleSummary, style: TextStyle(color: Colors.grey[700])),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  _navigateToStudentEligibility(exam.id);
                },
                child: const Text('Manage Eligibility'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _navigateToEditor(examId: exam.id),
                child: const Text('Manage Schedule'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToStudentEligibility(String examId) async {
    final institutionId = await SessionManager.getInstitutionId();
    if (!mounted) return;
    if (institutionId != null) {
      context.go('/$institutionId/admin/exam/$examId/eligibility');
    }
  }
}
