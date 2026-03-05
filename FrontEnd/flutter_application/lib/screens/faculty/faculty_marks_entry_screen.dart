import 'package:flutter/material.dart';
import 'package:flutter_application/models/course_model.dart';
import 'package:flutter_application/models/marks_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/attendance_service.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/faculty_layout.dart';

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
  bool _isDarkMode = false;

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
          SnackBar(content: Text('Error loading courses: $e'), behavior: SnackBarBehavior.floating),
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
          SnackBar(content: Text('Error loading students: $e'), behavior: SnackBarBehavior.floating),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAllMarks() async {
    if (_selectedCourse == null || _institutionId == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), behavior: SnackBarBehavior.floating),
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
          SnackBar(content: Text('Successfully saved marks for $savedCount students'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving marks: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);

    return FacultyLayout(
      title: 'Academic Records',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Marks Entry', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
      ],
      child: _isLoading && _facultyCourses.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student Marks Entry',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Record and update marks for various assessments',
                          style: TextStyle(fontSize: 14, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ],
                    ),
                    if (_students.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveAllMarks,
                        icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded, size: 18),
                        label: const Text('Save All Records'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildHeaderControls(),
                const SizedBox(height: 24),
                if (_isLoading && _students.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (_students.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.people_rounded, color: Color(0xFF4F46E5), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Student List (${_students.length})',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildStudentList()),
                ] else if (_selectedCourse != null)
                  _buildEmptyState('No students found in this course.', Icons.person_off_rounded)
                else
                  _buildEmptyState('Please select a course to enter marks.', Icons.school_outlined),
              ],
            ),
          ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: _isDarkMode ? Colors.grey[700] : Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderControls() {
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          DropdownButtonFormField<Course>(
            value: _selectedCourse,
            dropdownColor: cardColor,
            style: TextStyle(color: textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Course Selection',
              labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.book_rounded, size: 20),
            ),
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  dropdownColor: cardColor,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Assessment Type',
                    labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.assignment_rounded, size: 20),
                  ),
                  items: _markTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _totalMarksController,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Max Marks',
                    labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.score_rounded, size: 20),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _titleController,
            style: TextStyle(color: textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Assessment Title',
              labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'e.g. Quiz 1, Midterm Exam',
              prefixIcon: const Icon(Icons.title_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;

    return ListView.builder(
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  student.displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            title: Text(
              student.displayName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937)),
            ),
            subtitle: Text(
              student.usn ?? 'No USN',
              style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
            ),
            trailing: SizedBox(
              width: 100,
              height: 46,
              child: TextFormField(
                controller: _marksControllers[student.uid],
                style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Marks',
                  hintStyle: TextStyle(color: _isDarkMode ? Colors.grey[600] : Colors.grey[400], fontWeight: FontWeight.normal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  fillColor: _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
                  filled: true,
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

  Color get textPrimary => _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
}
