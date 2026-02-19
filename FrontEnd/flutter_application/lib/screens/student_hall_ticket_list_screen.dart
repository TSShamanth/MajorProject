import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/models/exam_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';

class StudentHallTicketListScreen extends StatefulWidget {
  const StudentHallTicketListScreen({super.key});

  @override
  StudentHallTicketListScreenState createState() =>
      StudentHallTicketListScreenState();
}

class StudentHallTicketListScreenState
    extends State<StudentHallTicketListScreen> {
  final ApiService _apiService = ApiService();
  List<Exam> _exams = [];
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
          final studentId = FirebaseAuth.instance.currentUser?.uid;
          if (institutionId == null || studentId == null) {
            if (mounted) setState(() => _isLoading = false);
            _errorMessage = 'User or Institution ID not found.';
            return;
          }
          
    
          final allExams = await _apiService.getExams(institutionId);
          final studentExams = allExams.where((exam) {
            return exam.frozenCandidateList != null && exam.frozenCandidateList!.contains(studentId);
          }).toList();
    
          if (mounted) {
            setState(() {
              _exams = studentExams;
              _isLoading = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to load exams: ${e.toString()}';
              _isLoading = false;
            });
          }
        }
      }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Hall Tickets'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _exams.isEmpty
                  ? const Center(child: Text('No hall tickets available for you.'))
                  : ListView.builder(
                      itemCount: _exams.length,
                      itemBuilder: (context, index) {
                        final exam = _exams[index];
                        return ListTile(
                          title: Text(exam.name),
                          subtitle: Text('Click to view'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () async {
                            final router = GoRouter.of(context);
                            final institutionId = await SessionManager.getInstitutionId();
                            if (!mounted) return;
                             if (institutionId != null) {
                                router.go('/$institutionId/student/hall-tickets/${exam.id}');
                             }
                          },
                        );
                      },
                    ),
    );
  }
}
