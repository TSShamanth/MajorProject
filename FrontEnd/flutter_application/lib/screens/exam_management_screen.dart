import 'package:flutter/material.dart';
import 'package:flutter_application/models/exam_model.dart';
import 'package:flutter_application/models/department_model.dart'; // Added import
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';

class ExamManagementScreen extends StatefulWidget {
  const ExamManagementScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ExamManagementScreenState createState() => _ExamManagementScreenState();
}

class _ExamManagementScreenState extends State<ExamManagementScreen> {
  late ApiService _apiService;
  List<Exam> _exams = [];
  List<Department> _departments = []; // New list to store departments
  bool _isLoadingExams = false; // Renamed for clarity
  bool _isLoadingDepartments = false; // New loading flag
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchData(); // Call a new method to fetch both exams and departments
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
        // Fetch exams
        final exams = await _apiService.getExams(institutionId);
        if (!mounted) return;
        setState(() {
          _exams = exams;
        });

        // Fetch departments
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

  // Helper method to get department name from ID
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
                        final institutionId = await SessionManager.getInstitutionId();
                        if (institutionId != null && mounted) {
                          context.go('/$institutionId/admin/exams/${exam.id}/eligibility');
                        }
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isNavigating ? null : () async {
          setState(() {
            _isNavigating = true;
          });
          try {
            final institutionId = await SessionManager.getInstitutionId();
            if (institutionId != null) {
              if (!mounted) return;
              context.go('/$institutionId/admin/create-exam');
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
