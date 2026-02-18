import 'package:flutter/material.dart';
import 'package:flutter_application/models/exam_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';

class StudentTimetableScreen extends StatefulWidget {
  const StudentTimetableScreen({super.key});

  @override
  StudentTimetableScreenState createState() => StudentTimetableScreenState();
}

class StudentTimetableScreenState extends State<StudentTimetableScreen> {
  late ApiService _apiService;
  List<Exam> _exams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId != null) {
        // TODO: This fetches all exams. We need an endpoint to fetch exams for a specific student.
        // For now, we'll just fetch all and filter on the client side.
        final allExams = await _apiService.getExams(institutionId);
        // TODO: Filter exams based on the logged-in student's department and semester.
        // This requires getting student details first.
        setState(() {
          _exams = allExams;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Timetables'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exams.isEmpty
              ? const Center(child: Text('No exam timetables found.'))
              : ListView.builder(
                  itemCount: _exams.length,
                  itemBuilder: (context, index) {
                    final exam = _exams[index];
                    return ListTile(
                      title: Text(exam.name),
                      subtitle: Text('Semester ${exam.semester}'),
                      onTap: () async {
                        final router = GoRouter.of(context);
                        final institutionId = await SessionManager.getInstitutionId();
                        if (mounted && institutionId != null) {
                          router.go('/$institutionId/student/timetable/${exam.id}');
                        }
                      },
                    );
                  },
                ),
    );
  }
}
