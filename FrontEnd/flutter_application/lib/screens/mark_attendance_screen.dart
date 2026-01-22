import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  List<Subject> subjects = [];
  List<Student> students = [];
  List<Student> filteredStudents = [];
  Subject? selectedSubject;
  DateTime selectedDate = DateTime.now();
  Map<String, bool> attendanceMap = {};
  Map<String, String> remarksMap = {};
  bool isLoading = false;
  String? errorMessage;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final loadedSubjects = await AttendanceService.getSubjects();
      if (mounted) {
        setState(() {
          subjects = loadedSubjects;
          isLoading = false;
          errorMessage = null;
        });
      }
    } on AttendanceException catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.message;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = AppConstants.errorLoadingSubjects;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStudents() async {
    if (selectedSubject == null) return;

    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final loadedStudents = await AttendanceService.getStudentsForSubject(selectedSubject!.id);
      if (mounted) {
        setState(() {
          students = loadedStudents;
          filteredStudents = loadedStudents;
          attendanceMap = {for (var student in loadedStudents) student.id: false};
          remarksMap = {for (var student in loadedStudents) student.id: ''};
          searchQuery = '';
          isLoading = false;
          errorMessage = null;
        });
      }
    } on AttendanceException catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.message;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = AppConstants.errorLoadingStudents;
          isLoading = false;
        });
      }
    }
  }

  void _filterStudents(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredStudents = students;
      } else {
        filteredStudents = students
            .where((student) =>
                student.name.toLowerCase().contains(query.toLowerCase()) ||
                student.usn.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _submitAttendance() async {
    if (selectedSubject == null) {
      _showErrorSnackbar(AppConstants.errorSelectSubject);
      return;
    }
    if (students.isEmpty) {
      _showErrorSnackbar('No students loaded. Please try again.');
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final dateStr = DateFormat(AppConstants.dateFormatStorage).format(selectedDate);
      final success = await AttendanceService.markAttendance(
        subjectId: selectedSubject!.id,
        studentAttendance: attendanceMap,
        date: dateStr,
      );

      if (success && mounted) {
        _showSuccessSnackbar(AppConstants.successAttendanceMarked);
        _resetForm();
      }
    } on AttendanceException catch (e) {
      if (mounted) {
        _showErrorSnackbar(e.message);
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(AppConstants.errorMarkingAttendance);
        setState(() => isLoading = false);
      }
    }
  }

  void _resetForm() {
    setState(() {
      selectedSubject = null;
      students = [];
      filteredStudents = [];
      attendanceMap = {};
      remarksMap = {};
      selectedDate = DateTime.now();
      searchQuery = '';
      isLoading = false;
      errorMessage = null;
    });
  }

  void _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && mounted) {
      setState(() => selectedDate = pickedDate);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          AppStrings.markAttendance,
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error Message
                  if (errorMessage != null) _buildErrorBanner(),

                  // Subject Selection
                  _buildSectionTitle(AppStrings.selectSubject),
                  const SizedBox(height: 8),
                  _buildSubjectDropdown(),
                  const SizedBox(height: 24),

                  // Date Selection
                  _buildSectionTitle(AppStrings.selectDate),
                  const SizedBox(height: 8),
                  _buildDatePicker(),
                  const SizedBox(height: 24),

                  // Students List with Search
                  if (students.isNotEmpty) ...[
                    _buildStudentListHeader(),
                    const SizedBox(height: 12),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                    const SizedBox(height: 12),
                    if (filteredStudents.isEmpty)
                      _buildEmptySearchState()
                    else
                      _buildStudentsList(),
                  ] else if (selectedSubject != null) ...[
                    _buildEmptyState(AppStrings.noStudentsFound),
                  ],

                  const SizedBox(height: 32),

                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade700, size: 18),
            onPressed: () => setState(() => errorMessage = null),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        color: Colors.white,
      ),
      child: DropdownButton<Subject>(
        value: selectedSubject,
        isExpanded: true,
        underline: const SizedBox(),
        items: subjects
            .map((subject) => DropdownMenuItem(
                  value: subject,
                  child: SizedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(subject.name, style: const TextStyle(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                            '${subject.code} • ${subject.className}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
            .toList(),
        onChanged: (subject) {
          setState(() => selectedSubject = subject);
          if (subject != null) _loadStudents();
        },
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        color: Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Text(
                  DateFormat(AppConstants.dateFormatDisplay).format(selectedDate),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${AppStrings.attendance} (${filteredStudents.length}/${students.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            border: Border.all(color: Colors.green.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${attendanceMap.values.where((v) => v).length}/${students.length} Present',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        color: Colors.white,
      ),
      child: TextField(
        onChanged: _filterStudents,
        decoration: InputDecoration(
          hintText: 'Search by name or USN...',
          hintStyle: TextStyle(color: Colors.grey.shade600),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade600),
                  onPressed: () => _filterStudents(''),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildQuickActionButton(
            'Mark All Present',
            Icons.check_circle,
            Colors.green,
            () {
              setState(() {
                for (var student in filteredStudents) {
                  attendanceMap[student.id] = true;
                }
              });
            },
          ),
          const SizedBox(width: 8),
          _buildQuickActionButton(
            'Mark All Absent',
            Icons.cancel,
            Colors.red,
            () {
              setState(() {
                for (var student in filteredStudents) {
                  attendanceMap[student.id] = false;
                }
              });
            },
          ),
          const SizedBox(width: 8),
          _buildQuickActionButton(
            'Clear Selection',
            Icons.refresh,
            Colors.orange,
            () {
              setState(() {
                for (var student in students) {
                  attendanceMap[student.id] = false;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off, color: Colors.grey.shade600, size: 48),
            const SizedBox(height: 8),
            Text(
              'No students found matching "$searchQuery"',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        final isPresent = attendanceMap[student.id] ?? false;
        final remarks = remarksMap[student.id] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isPresent ? Colors.green.shade300 : Colors.grey.shade300,
              width: isPresent ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
          child: ExpansionTile(
            title: Row(
              children: [
                Checkbox(
                  value: isPresent,
                  onChanged: (value) {
                    setState(() {
                      attendanceMap[student.id] = value ?? false;
                    });
                  },
                  activeColor: Colors.green.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        student.usn,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
                    border: Border.all(
                      color: isPresent ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPresent ? 'Present' : 'Absent',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Add Remarks (Optional)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.grey.shade50,
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            remarksMap[student.id] = value;
                          });
                        },
                        controller: TextEditingController(text: remarks),
                        maxLines: 2,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'e.g., Late arrival, Medical leave, etc.',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(10),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: students.isEmpty ? null : _submitAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
            ),
            child: const Text(
              AppStrings.submit,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _resetForm,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Text(
              AppStrings.reset,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
