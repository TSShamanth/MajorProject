import 'package:flutter/material.dart';
import 'package:flutter_application/models/exam_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';

class ExamHallTicketsScreen extends StatefulWidget {
  final String examId;

  const ExamHallTicketsScreen({super.key, required this.examId});

  @override
  ExamHallTicketsScreenState createState() => ExamHallTicketsScreenState();
}

class ExamHallTicketsScreenState extends State<ExamHallTicketsScreen> {
  final ApiService _apiService = ApiService();
  Exam? _exam;
  List<UserModel> _students = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) {
        if (mounted) setState(() => _isLoading = false);
        _errorMessage = 'Institution ID not found.';
        return;
      }

      final exam = await _apiService.getExamById(institutionId, widget.examId);
      if (exam.frozenCandidateList != null && exam.frozenCandidateList!.isNotEmpty) {
        // Fetch all users and filter by the frozen list
        final allUsers = await _apiService.getUsers(institutionId);
        _students = allUsers.where((user) => exam.frozenCandidateList!.contains(user.uid)).toList();
      }
      
      if (mounted) {
        setState(() {
          _exam = exam;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hall Tickets - ${_exam?.name ?? ''}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _exam == null
                  ? const Center(child: Text('Exam not found.'))
                  : _students.isEmpty
                      ? const Center(child: Text('No students found for this exam.'))
                      : ListView.builder(
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            return ListTile(
                              title: Text(student.displayName),
                              subtitle: Text(student.usn ?? student.email ?? 'N/A'),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () async {
                                final router = GoRouter.of(context);
                                final institutionId = await SessionManager.getInstitutionId();
                                if (!mounted) return;
                                if (institutionId != null) {
                                  router.go('/$institutionId/admin/exams/${_exam!.id}/hall-tickets/${student.uid}');
                                }
                              },
                            );
                          },
                        ),
    );
  }
}
