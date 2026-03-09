import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';
import '../services/session_manager.dart';
import '../widgets/faculty_layout.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  // ── Business logic state ──────────────────────────────────────────────────
  List<Course> _courses = [];
  List<UserModel> _students = [];
  List<UserModel> _filteredStudents = [];
  Course? _selectedCourse;
  DateTime _selectedDate = DateTime.now();
  Map<String, bool> _attendanceMap = {};
  Map<String, String> _remarksMap = {};
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _institutionId;
  String? _facultyUid;
  bool _isDarkMode = false;

  // ── Theme helpers ──────────────────────────────────────────────────────────
  static const _accent  = Color(0xFF4F46E5);
  static const _success = Color(0xFF10B981);
  static const _danger  = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    _institutionId = await SessionManager.getInstitutionId();
    _facultyUid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (_institutionId == null || _facultyUid == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not retrieve institution or faculty ID.';
        });
      }
      return;
    }
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final loadedCourses = await AttendanceService.getSubjects();
      if (mounted) {
        setState(() {
          _courses = loadedCourses;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading courses: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedCourse == null) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final loadedStudents = await AttendanceService.getStudentsForSubject(_selectedCourse!.courseCode);
      if (mounted) {
        setState(() {
          _students = loadedStudents;
          _filteredStudents = loadedStudents;
          _attendanceMap = {for (var s in loadedStudents) s.uid: false};
          _remarksMap = {for (var s in loadedStudents) s.uid: ''};
          _searchQuery = '';
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading students: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      _filteredStudents = query.isEmpty
          ? _students
          : _students
              .where((s) =>
                  s.displayName.toLowerCase().contains(query.toLowerCase()) ||
                  (s.usn != null && s.usn!.toLowerCase().contains(query.toLowerCase())))
              .toList();
    });
  }

  Future<void> _submitAttendance() async {
    if (_selectedCourse == null) {
      _showSnackbar('Please select a course.', isError: true);
      return;
    }
    if (_students.isEmpty) {
      _showSnackbar('No students loaded.', isError: true);
      return;
    }
    if (_institutionId == null || _facultyUid == null) {
      _showSnackbar('Missing IDs for submission.', isError: true);
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      List<AttendanceModel> attendanceRecords = _students.map((student) {
        return AttendanceModel(
          courseCode: _selectedCourse!.courseCode,
          studentUid: student.uid,
          date: dateStr,
          status: _attendanceMap[student.uid] == true ? 'Present' : 'Absent',
          remarks: _remarksMap[student.uid],
          facultyUid: _facultyUid,
          institutionId: _institutionId!,
          departmentId: _selectedCourse!.departmentId ?? 'N/A',
        );
      }).toList();

      final success = await AttendanceService.markAttendance(
        courseCode: _selectedCourse!.courseCode,
        institutionId: _institutionId!,
        departmentId: _selectedCourse!.departmentId ?? 'N/A',
        facultyUid: _facultyUid!,
        attendanceRecords: attendanceRecords,
      );

      if (success && mounted) {
        _showSnackbar('Attendance marked successfully!', isError: false);
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Error: ${e.toString()}', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedCourse = null;
      _students = [];
      _filteredStudents = [];
      _attendanceMap = {};
      _remarksMap = {};
      _selectedDate = DateTime.now();
      _searchQuery = '';
      _isLoading = false;
      _errorMessage = null;
    });
    _loadCourses();
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _danger : _success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);

    return FacultyLayout(
      title: 'Attendance',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Mark Attendance', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
      ],
      child: _isLoading && _courses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 768;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
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
                                    'Attendance Tracking',
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Select session details and mark presence',
                                    style: TextStyle(fontSize: 14, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                ],
                              ),
                              if (_students.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _submitAttendance,
                                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                                  label: const Text('Submit Attendance'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          if (_errorMessage != null) _buildErrorBanner(),

                          _buildSessionCard(),
                          const SizedBox(height: 24),

                          if (_students.isNotEmpty) ...[
                            _buildStudentsSection(isMobile),
                            const SizedBox(height: 24),
                            _buildActionButtons(isMobile),
                          ] else if (_selectedCourse != null) ...[
                            _buildEmptyState('No students found for this course.', Icons.people_outline_rounded),
                          ] else ...[
                            _buildEmptyState('Please select a course to start marking attendance.', Icons.assignment_turned_in_rounded),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _danger),
          const SizedBox(width: 12),
          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: _danger, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildSessionCard() {
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: _accent, size: 20),
              const SizedBox(width: 12),
              const Text('Session Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<Course>(
            value: _selectedCourse,
            dropdownColor: cardColor,
            decoration: InputDecoration(
              labelText: 'Select Course',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.book_rounded, size: 20),
            ),
            items: _courses.map((c) => DropdownMenuItem(
              value: c,
              child: Text('${c.courseCode} - ${c.courseName}'),
            )).toList(),
            onChanged: (course) {
              setState(() => _selectedCourse = course);
              if (course != null) _loadStudents();
            },
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _selectDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Session Date',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
              ),
              child: Text(DateFormat('EEEE, dd MMM yyyy').format(_selectedDate)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsSection(bool isMobile) {
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.groups_rounded, color: _success, size: 20),
                  SizedBox(width: 12),
                  Text('Student Roster', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              _buildAttendanceStats(),
            ],
          ),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildQuickActions(),
          const SizedBox(height: 20),
          if (_filteredStudents.isEmpty)
            Center(child: Text('No students match "$_searchQuery"', style: const TextStyle(color: Colors.grey)))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) => _buildStudentTile(_filteredStudents[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStats() {
    final present = _attendanceMap.values.where((v) => v).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _success.withOpacity(0.3)),
      ),
      child: Text(
        '$present/${_students.length} Present',
        style: const TextStyle(color: _success, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: _filterStudents,
      decoration: InputDecoration(
        hintText: 'Search by name or USN...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _quickActionBtn('All Present', Icons.check_circle_outline_rounded, _success, () {
          setState(() { for (var s in _filteredStudents) { _attendanceMap[s.uid] = true; } });
        }),
        const SizedBox(width: 12),
        _quickActionBtn('All Absent', Icons.cancel_outlined, _danger, () {
          setState(() { for (var s in _filteredStudents) { _attendanceMap[s.uid] = false; } });
        }),
      ],
    );
  }

  Widget _quickActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentTile(UserModel student) {
    final isPresent = _attendanceMap[student.uid] ?? false;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPresent ? _success.withOpacity(0.5) : borderColor),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Checkbox(
            value: isPresent,
            activeColor: _success,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (val) => setState(() => _attendanceMap[student.uid] = val ?? false),
          ),
          title: Text(student.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(student.usn ?? 'No USN', style: const TextStyle(fontSize: 12)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isPresent ? _success : _danger).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isPresent ? 'Present' : 'Absent',
              style: TextStyle(color: isPresent ? _success : _danger, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextFormField(
                initialValue: _remarksMap[student.uid],
                onChanged: (val) => _remarksMap[student.uid] = val,
                decoration: InputDecoration(
                  labelText: 'Remarks (Optional)',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _resetForm,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reset Form'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _submitAttendance,
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Submit Attendance'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icon, size: 64, color: _isDarkMode ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
