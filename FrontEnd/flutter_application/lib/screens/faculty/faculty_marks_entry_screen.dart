import 'package:flutter/material.dart';
import 'package:flutter_application/models/course_model.dart';
import 'package:flutter_application/models/marks_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/attendance_service.dart';
import 'package:go_router/go_router.dart';

class FacultyMarksEntryScreen extends StatefulWidget {
  const FacultyMarksEntryScreen({super.key});

  @override
  State<FacultyMarksEntryScreen> createState() => _FacultyMarksEntryScreenState();
}

class _FacultyMarksEntryScreenState extends State<FacultyMarksEntryScreen> {
  final ApiService _apiService = ApiService();
  String? _institutionId;
  
  List<Course> _facultyCourses = [];
  Course? _selectedCourse;
  String _selectedType = 'Assignment';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _totalMarksController = TextEditingController(text: '100');
  
  List<UserModel> _students = [];
  Map<String, TextEditingController> _marksControllers = {};
  
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _markTypes = ['Assignment', 'Internal Test', 'Project', 'Final Exam'];

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
      
      if (mounted) {
        setState(() {
          _facultyCourses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading courses: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedCourse == null) return;

    setState(() => _isLoading = true);
    try {
      final loadedStudents = await AttendanceService.getStudentsForSubject(_selectedCourse!.courseCode);

      if (mounted) {
        setState(() {
          _students = loadedStudents;
          _marksControllers = {
            for (var student in _students) 
              student.uid: TextEditingController()
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAllMarks() async {
    if (_selectedCourse == null || _institutionId == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final totalMarks = double.tryParse(_totalMarksController.text) ?? 100.0;
    
    setState(() => _isSaving = true);
    try {
      int savedCount = 0;
      for (var student in _students) {
        final obtainedStr = _marksControllers[student.uid]?.text;
        if (obtainedStr != null && obtainedStr.isNotEmpty) {
          final obtained = double.tryParse(obtainedStr) ?? 0.0;
          
          final marks = MarksModel(
            studentId: student.uid,
            courseCode: _selectedCourse!.courseCode,
            institutionId: _institutionId!,
            semester: _selectedCourse!.semester,
            type: _selectedType,
            title: _titleController.text,
            obtainedMarks: obtained,
            totalMarks: totalMarks,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
          
          await _apiService.saveMarks(_institutionId!, marks);
          savedCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully saved marks for $savedCount students'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving marks: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Student Marks'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderControls(),
                const SizedBox(height: 20),
                if (_students.isNotEmpty) ...[
                  const Text(
                    'Student List',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: _buildStudentList()),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAllMarks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save All Marks'),
                    ),
                  ),
                ] else if (_selectedCourse != null)
                  const Center(child: Text('No students found in this course'))
                else
                  const Center(child: Text('Please select a course to enter marks')),
              ],
            ),
          ),
    );
  }

  Widget _buildHeaderControls() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<Course>(
              value: _selectedCourse,
              decoration: const InputDecoration(labelText: 'Select Course', border: OutlineInputBorder()),
              items: _facultyCourses.map((c) => DropdownMenuItem(
                value: c,
                child: Text('${c.courseCode} - ${c.courseName}'),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCourse = value;
                  _students = [];
                });
                _loadStudents();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(labelText: 'Assessment Type', border: OutlineInputBorder()),
                    items: _markTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (value) => setState(() => _selectedType = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _totalMarksController,
                    decoration: const InputDecoration(labelText: 'Total Marks', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Assessment Title (e.g. Quiz 1, Midterm)',
                border: OutlineInputBorder(),
                hintText: 'Enter title for this entry',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(student.displayName),
            subtitle: Text(student.usn ?? student.uid),
            trailing: SizedBox(
              width: 100,
              child: TextFormField(
                controller: _marksControllers[student.uid],
                decoration: const InputDecoration(
                  hintText: 'Marks',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
