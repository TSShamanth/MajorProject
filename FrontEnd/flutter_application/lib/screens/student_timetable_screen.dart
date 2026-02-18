import 'package:flutter/material.dart';
import 'package:flutter_application/models/exam_model.dart';
import 'package:flutter_application/models/user_model.dart';
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
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // Fetch user and exams in parallel
      final results = await Future.wait([
        _apiService.getMe(institutionId),
        _apiService.getExams(institutionId),
      ]);

      final user = results[0] as UserModel;
      final allExams = results[1] as List<Exam>;

      final filteredExams = allExams.where((exam) {
        return exam.departmentId == user.departmentId && exam.semester == user.sem;
      }).toList();

      if (mounted) {
        setState(() {
          _exams = filteredExams;
          _isLoading = false;
        });
      }
    } catch (e) {
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
        title: const Text('Exam Timetables'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exams.isEmpty
              ? const Center(child: Text('No exam timetables found for your department and semester.'))
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
