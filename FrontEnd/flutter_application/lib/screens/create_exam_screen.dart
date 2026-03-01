import 'package:flutter/material.dart';
import 'package:flutter_application/models/course_model.dart';
import 'package:flutter_application/models/department_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_layout.dart';

class CreateExamScreen extends StatefulWidget {
  const CreateExamScreen({super.key});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _examNameController = TextEditingController();
  final _examDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _durationController = TextEditingController();
  
  String? _selectedDepartment;
  String? _selectedSemester;
  List<String> _selectedSubjects = [];

  late ApiService _apiService;
  List<Department> _departments = [];
  List<Course> _courses = [];
  
  bool _isLoadingDepartments = false;
  bool _isLoadingCourses = false;
  bool _isCreating = false;
  bool _isDarkMode = false;
  String? _institutionId;

  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _initData();
  }

  Future<void> _initData() async {
    final id = await SessionManager.getInstitutionId();
    if (mounted) setState(() => _institutionId = id);
    if (id != null) _fetchDepartments();
  }

  @override
  void dispose() {
    _examNameController.dispose();
    _examDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _fetchDepartments() async {
    if (!mounted || _institutionId == null) return;
    setState(() => _isLoadingDepartments = true);
    try {
      final departments = await _apiService.getDepartments(_institutionId!);
      if (mounted) setState(() => _departments = departments);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load departments: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingDepartments = false);
    }
  }

  Future<void> _fetchCourses(String departmentId) async {
    if (!mounted || _institutionId == null) return;
    setState(() {
      _isLoadingCourses = true;
      _courses = [];
      _selectedSubjects = [];
    });
    try {
      final courses = await _apiService.getCourses(_institutionId!, departmentId);
      if (mounted) setState(() => _courses = courses);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load courses: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: _isDarkMode ? ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFF4F46E5), onPrimary: Colors.white, surface: Color(0xFF1F2937), onSurface: Colors.white),
          ) : ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4F46E5), onPrimary: Colors.white, surface: Colors.white, onSurface: Color(0xFF1F2937)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _examDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, {required bool isStartTime}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? (_selectedStartTime ?? TimeOfDay.now()) : (_selectedEndTime ?? TimeOfDay.now()),
      builder: (context, child) {
        return Theme(
          data: _isDarkMode ? ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFF4F46E5), onPrimary: Colors.white, surface: Color(0xFF1F2937), onSurface: Colors.white),
          ) : ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4F46E5), onPrimary: Colors.white, surface: Colors.white, onSurface: Color(0xFF1F2937)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = picked;
          _startTimeController.text = picked.format(context);
        } else {
          _selectedEndTime = picked;
          _endTimeController.text = picked.format(context);
        }
        _calculateDuration();
      });
    }
  }

  void _calculateDuration() {
    if (_selectedStartTime != null && _selectedEndTime != null) {
      final now = DateTime.now();
      final startDateTime = DateTime(now.year, now.month, now.day, _selectedStartTime!.hour, _selectedStartTime!.minute);
      final endDateTime = DateTime(now.year, now.month, now.day, _selectedEndTime!.hour, _selectedEndTime!.minute);

      Duration duration = endDateTime.isBefore(startDateTime)
          ? endDateTime.add(const Duration(days: 1)).difference(startDateTime)
          : endDateTime.difference(startDateTime);

      _durationController.text = '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      _durationController.text = '';
    }
  }

  Future<void> _createExam() async {
    if (!_formKey.currentState!.validate() || _institutionId == null) return;
    
    if (_selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one subject.')));
      return;
    }

    setState(() => _isCreating = true);

    try {
      final examData = {
        'name': _examNameController.text,
        'departmentId': _selectedDepartment,
        'semester': _selectedSemester,
        'subjects': _selectedSubjects,
        'examDate': _examDateController.text,
        'startTime': _startTimeController.text,
        'endTime': _endTimeController.text,
        'duration': _durationController.text,
      };
      final response = await _apiService.createExam(_institutionId!, examData);
      
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exam created successfully!'), backgroundColor: Colors.green));
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create exam: ${response.body}'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: 'Schedule Exam',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => context.push('/$_institutionId/admin/exam-management'),
          child: Text('Exams', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Schedule New', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Schedule New Examination', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('Define exam details, timing, and target subjects', style: TextStyle(fontSize: 14, color: textSecondary)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _isCreating ? null : _createExam,
                    icon: _isCreating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Create Exam'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              _buildFormSection(
                'General Details',
                'Basic information about the examination',
                Icons.info_outline_rounded,
                const Color(0xFF3B82F6),
                [
                  _buildTextField(_examNameController, 'Exam Name', Icons.edit_note_rounded, 'e.g., Mid-Term 2024, Final Sem Exam'),
                ],
              ),
              const SizedBox(height: 24),

              _buildFormSection(
                'Target Audience & Subjects',
                'Select the department, semester, and courses to evaluate',
                Icons.school_rounded,
                const Color(0xFF10B981),
                [
                  Row(
                    children: [
                      Expanded(
                        child: _isLoadingDepartments
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<String>(
                                value: _selectedDepartment,
                                dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                                style: TextStyle(color: textPrimary, fontSize: 15),
                                decoration: _inputDecoration('Department', Icons.business_rounded, 'Select Department'),
                                items: _departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedDepartment = val;
                                    if (val != null) _fetchCourses(val);
                                  });
                                },
                                validator: (val) => val == null ? 'Please select a department' : null,
                              ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSemester,
                          dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                          style: TextStyle(color: textPrimary, fontSize: 15),
                          decoration: _inputDecoration('Semester', Icons.format_list_numbered_rounded, 'Select Semester'),
                          items: List.generate(8, (i) => (i + 1).toString()).map((s) => DropdownMenuItem(value: s, child: Text('Semester $s'))).toList(),
                          onChanged: (val) => setState(() => _selectedSemester = val),
                          validator: (val) => val == null ? 'Please select a semester' : null,
                        ),
                      ),
                    ],
                  ),
                  if (_selectedDepartment != null) ...[
                    const SizedBox(height: 24),
                    Text('Select Subjects', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: _isDarkMode ? const Color(0xFF111827).withOpacity(0.5) : Colors.grey[50]!,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                      ),
                      child: _isLoadingCourses
                        ? const Center(child: CircularProgressIndicator())
                        : _courses.isEmpty
                          ? Center(child: Text('No courses found for this department.', style: TextStyle(color: textSecondary)))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _courses.length,
                              itemBuilder: (context, index) {
                                final course = _courses[index];
                                final isSelected = _selectedSubjects.contains(course.courseCode);
                                return CheckboxListTile(
                                  title: Text(course.courseName, style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                                  subtitle: Text(course.courseCode, style: TextStyle(color: textSecondary, fontSize: 12)),
                                  value: isSelected,
                                  activeColor: const Color(0xFF4F46E5),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedSubjects.add(course.courseCode);
                                      } else {
                                        _selectedSubjects.remove(course.courseCode);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              _buildFormSection(
                'Schedule & Timing',
                'Set the date, start time, and calculate duration',
                Icons.access_time_filled_rounded,
                const Color(0xFFF59E0B),
                [
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: _buildTextField(_examDateController, 'Exam Date', Icons.calendar_today_rounded, 'Select date'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context, isStartTime: true),
                          child: AbsorbPointer(
                            child: _buildTextField(_startTimeController, 'Start Time', Icons.play_circle_outline_rounded, 'Select start time'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context, isStartTime: false),
                          child: AbsorbPointer(
                            child: _buildTextField(_endTimeController, 'End Time', Icons.stop_circle_outlined, 'Select end time'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(_durationController, 'Total Duration', Icons.timer_rounded, 'Calculated automatically', isReadOnly: true),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(String title, String subtitle, IconData icon, Color color, List<Widget> children) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937))),
                      Text(subtitle, style: TextStyle(fontSize: 13, color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String hint, {bool isReadOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: isReadOnly,
      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87, fontSize: 15),
      decoration: _inputDecoration(label, icon, hint),
      validator: (v) => v!.isEmpty ? '$label is required' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!),
      hintStyle: TextStyle(color: _isDarkMode ? Colors.grey[600]! : Colors.grey[400]!, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF4F46E5).withOpacity(0.7), size: 20),
      filled: true,
      fillColor: _isDarkMode ? const Color(0xFF111827).withOpacity(0.5) : Colors.grey[50]!,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
