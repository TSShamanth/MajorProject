import 'package:flutter/material.dart';
import 'package:flutter_application/models/assessment_model.dart';
import 'package:flutter_application/models/course_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/attendance_service.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/faculty_layout.dart';

class FacultyAssessmentManagementScreen extends StatefulWidget {
  const FacultyAssessmentManagementScreen({super.key});

  @override
  State<FacultyAssessmentManagementScreen> createState() => _FacultyAssessmentManagementScreenState();
}

class _FacultyAssessmentManagementScreenState extends State<FacultyAssessmentManagementScreen> {
  final ApiService _apiService = ApiService();
  String? _institutionId;
  List<Course> _courses = [];
  Course? _selectedCourse;
  List<AssessmentModel> _assessments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _institutionId = GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'];
    if (_institutionId == null) return;

    try {
      final courses = await AttendanceService.getSubjects();
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading courses: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAssessments() async {
    if (_selectedCourse == null || _institutionId == null) return;
    setState(() => _isLoading = true);
    try {
      final assessments = await _apiService.getAssessmentsByCourse(_institutionId!, _selectedCourse!.courseCode);
      setState(() {
        _assessments = assessments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading assessments: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showAddAssessmentDialog() {
    final titleController = TextEditingController();
    final maxMarksController = TextEditingController(text: '100');
    final weightageController = TextEditingController(text: '0.1');
    String selectedType = 'Assignment';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Assessment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                items: ['Assignment', 'Internal Test', 'Project', 'Final Exam']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => selectedType = v!,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title (e.g. Quiz 1)'),
              ),
              TextField(
                controller: maxMarksController,
                decoration: const InputDecoration(labelText: 'Max Marks'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: weightageController,
                decoration: const InputDecoration(labelText: 'Weightage (0.0 to 1.0)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              
              final assessment = AssessmentModel(
                institutionId: _institutionId!,
                courseCode: _selectedCourse!.courseCode,
                semester: _selectedCourse!.semester,
                type: selectedType,
                title: titleController.text,
                maxMarks: double.tryParse(maxMarksController.text) ?? 100.0,
                weightage: double.tryParse(weightageController.text) ?? 0.1,
                date: DateTime.now().millisecondsSinceEpoch,
              );

              try {
                await _apiService.createAssessment(_institutionId!, assessment);
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadAssessments();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FacultyLayout(
      title: 'Assessment Management',
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Course Evaluations', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                if (_selectedCourse != null)
                  ElevatedButton.icon(
                    onPressed: _showAddAssessmentDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Assessment'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<Course>(
              value: _selectedCourse,
              hint: const Text('Select Course'),
              items: _courses.map((c) => DropdownMenuItem(value: c, child: Text('${c.courseCode} - ${c.courseName}'))).toList(),
              onChanged: (v) {
                setState(() => _selectedCourse = v);
                _loadAssessments();
              },
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_selectedCourse == null)
              const Center(child: Text('Select a course to manage assessments'))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _assessments.length,
                  itemBuilder: (context, index) {
                    final a = _assessments[index];
                    return Card(
                      child: ListTile(
                        title: Text(a.title),
                        subtitle: Text('${a.type} • Weightage: ${(a.weightage * 100).toStringAsFixed(0)}%'),
                        trailing: Text('Max: ${a.maxMarks}'),
                        onLongPress: () async {
                           // Simple delete on long press
                           await _apiService.deleteAssessment(_institutionId!, a.id!);
                           _loadAssessments();
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
