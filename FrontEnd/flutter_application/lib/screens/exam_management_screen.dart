import 'package:flutter/material.dart';
import 'package:flutter_application/models/exam_model.dart';
import 'package:flutter_application/models/department_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';

class ExamManagementScreen extends StatefulWidget {
  const ExamManagementScreen({super.key});

  @override
  ExamManagementScreenState createState() => ExamManagementScreenState();
}

class ExamManagementScreenState extends State<ExamManagementScreen> {
  late ApiService _apiService;
  List<Exam> _exams = [];
  List<Department> _departments = [];
  bool _isLoadingExams = false;
  bool _isLoadingDepartments = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingExams = true;
      _isLoadingDepartments = true;
    });

    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId != null) {
        final exams = await _apiService.getExams(institutionId);
        if (!mounted) return;
        setState(() {
          _exams = exams;
        });

        final departments = await _apiService.getDepartments(institutionId);
        if (!mounted) return;
        setState(() {
          _departments = departments;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      if(mounted) {
        setState(() {
          _isLoadingExams = false;
          _isLoadingDepartments = false;
        });
      }
    }
  }

  String _getDepartmentName(String departmentId) {
    return _departments.firstWhere(
      (dept) => dept.id == departmentId,
      orElse: () => Department(id: departmentId, name: 'Unknown Department', shortName: '', institutionId: ''),
    ).name;
  }

  @override
  Widget build(BuildContext context) {
    final bool overallLoading = _isLoadingExams || _isLoadingDepartments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Examination Management'),
      ),
      body: overallLoading
          ? const Center(child: CircularProgressIndicator())
          : _exams.isEmpty
              ? const Center(child: Text('No exams scheduled.'))
              : ListView.builder(
                  itemCount: _exams.length,
                  itemBuilder: (context, index) {
                    final exam = _exams[index];
                    final departmentName = _getDepartmentName(exam.departmentId);
                    return ListTile(
                      title: Text(exam.name),
                      subtitle: Text('$departmentName - ${exam.semester}'),
                      onTap: () async {
                        final router = GoRouter.of(context);
                        final institutionId = await SessionManager.getInstitutionId();
                        if (mounted && institutionId != null) {
                          router.go('/$institutionId/admin/exams/${exam.id}/eligibility');
                        }
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.people_alt_outlined),
                            tooltip: 'Student Eligibility',
                            onPressed: _isNavigating ? null : () async {
                              setState(() => _isNavigating = true);
                              final router = GoRouter.of(context);
                              try {
                                final institutionId = await SessionManager.getInstitutionId();
                                if (mounted && institutionId != null) {
                                  router.go('/$institutionId/admin/exams/${exam.id}/eligibility');
                                }
                              } finally {
                                if (mounted) setState(() => _isNavigating = false);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_calendar),
                            tooltip: 'Edit Schedule',
                            onPressed: _isNavigating ? null : () async {
                              setState(() => _isNavigating = true);
                              final router = GoRouter.of(context);
                              try {
                                final institutionId = await SessionManager.getInstitutionId();
                                if (mounted && institutionId != null) {
                                  router.go('/$institutionId/admin/exams/${exam.id}/schedule-management');
                                }
                              } finally {
                                if (mounted) setState(() => _isNavigating = false);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: 'View Timetable',
                            onPressed: _isNavigating ? null : () async {
                              setState(() => _isNavigating = true);
                              final router = GoRouter.of(context);
                              try {
                                final institutionId = await SessionManager.getInstitutionId();
                                if (mounted && institutionId != null) {
                                  router.go('/$institutionId/admin/exams/${exam.id}/timetable');
                                }
                              } finally {
                                if (mounted) setState(() => _isNavigating = false);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.chair_alt),
                            tooltip: 'Hall Allocation',
                            onPressed: _isNavigating ? null : () async {
                              setState(() => _isNavigating = true);
                              final router = GoRouter.of(context);
                              try {
                                final institutionId = await SessionManager.getInstitutionId();
                                if (mounted && institutionId != null) {
                                  router.go('/$institutionId/admin/exams/${exam.id}/hall-allocation');
                                }
                              } finally {
                                if (mounted) setState(() => _isNavigating = false);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isNavigating ? null : () async {
          setState(() {
            _isNavigating = true;
          });
          final router = GoRouter.of(context);
          try {
            final institutionId = await SessionManager.getInstitutionId();
            if (mounted && institutionId != null) {
              router.go('/$institutionId/admin/create-exam');
            }
          } finally {
            if (mounted) {
              setState(() {
                _isNavigating = false;
              });
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
