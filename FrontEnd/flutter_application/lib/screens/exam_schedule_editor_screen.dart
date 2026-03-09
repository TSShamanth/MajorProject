import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/models/exam_model.dart' as app_models;
import 'package:flutter_application/models/exam_schedule_entry.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_layout.dart';

class ExamScheduleEditorScreen extends StatefulWidget {
  final String? examId;

  const ExamScheduleEditorScreen({super.key, this.examId});

  @override
  State<ExamScheduleEditorScreen> createState() => _ExamScheduleEditorScreenState();
}

class _ExamScheduleEditorScreenState extends State<ExamScheduleEditorScreen> {
  final ApiService _apiService = ApiService();
  app_models.Exam? _exam;
  bool _isLoading = true;
  String _errorMessage = '';
  String? _institutionId;
  bool _isDarkMode = false;

  final Map<String, Map<String, TextEditingController>> _scheduleControllers = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (_institutionId != null) {
      _fetchExamDetails();
    }
  }

  Future<void> _fetchExamDetails() async {
    if (!mounted || _institutionId == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (widget.examId != null) {
        final fetchedExam = await _apiService.getExamById(_institutionId!, widget.examId!);
        if (!mounted) return;
        setState(() {
          _exam = fetchedExam;
        });

        if (_exam != null && _exam!.subjects.isNotEmpty) {
          for (var subjectCode in _exam!.subjects) {
            _scheduleControllers[subjectCode] = {
              'date': TextEditingController(),
              'startTime': TextEditingController(),
              'endTime': TextEditingController(),
              'duration': TextEditingController(),
            };
            if (_exam!.schedule.containsKey(subjectCode)) {
              final entry = _exam!.schedule[subjectCode]!;
              _scheduleControllers[subjectCode]!['date']!.text = entry.date;
              _scheduleControllers[subjectCode]!['startTime']!.text = entry.startTime;
              _scheduleControllers[subjectCode]!['endTime']!.text = entry.endTime;
              _scheduleControllers[subjectCode]!['duration']!.text = entry.duration;
            }
          }
        }
      } else {
        _errorMessage = 'No exam selected for scheduling.';
      }
    } catch (e) {
      if (mounted) _errorMessage = 'Failed to load exam details: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSchedule() async {
    if (!mounted || _institutionId == null || _exam == null) return;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);

    try {
      Map<String, ExamScheduleEntry> newSchedule = {};
      for (var subjectCode in _exam!.subjects) {
        final controllers = _scheduleControllers[subjectCode];
        if (controllers != null &&
            controllers['date']!.text.isNotEmpty &&
            controllers['startTime']!.text.isNotEmpty) {
          newSchedule[subjectCode] = ExamScheduleEntry(
            date: controllers['date']!.text,
            startTime: controllers['startTime']!.text,
            endTime: controllers['endTime']!.text,
            duration: controllers['duration']!.text,
          );
        }
      }

      await _apiService.updateExamSchedule(_institutionId!, _exam!.id, newSchedule);
      messenger.showSnackBar(const SnackBar(content: Text('Exam schedule updated successfully!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
      if (mounted) context.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to save schedule: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      controller.text = picked.format(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: 'Schedule Editor',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => context.push('/$_institutionId/admin/exam-management'),
          child: Text('Exams', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Schedule Editor', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: _isLoading && _exam == null
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
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
                                _exam!.name,
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage subject-wise dates and time slots',
                                style: TextStyle(fontSize: 14, color: textSecondary),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveSchedule,
                            icon: const Icon(Icons.save_rounded, size: 18),
                            label: const Text('Save Schedule'),
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
                      
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _exam!.subjects.length,
                        itemBuilder: (context, index) {
                          final subjectCode = _exam!.subjects[index];
                          return _buildSubjectCard(subjectCode, textPrimary, textSecondary);
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSubjectCard(String subjectCode, Color textPrimary, Color textSecondary) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF4F46E5), size: 20),
                ),
                const SizedBox(width: 16),
                Text(subjectCode, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: _buildTimeField(subjectCode, 'date', 'Exam Date', Icons.calendar_today_rounded, () => _selectDate(_scheduleControllers[subjectCode]!['date']!))),
                      const SizedBox(width: 20),
                      Expanded(child: _buildTimeField(subjectCode, 'startTime', 'Start Time', Icons.play_circle_outline_rounded, () => _selectTime(_scheduleControllers[subjectCode]!['startTime']!))),
                      const SizedBox(width: 20),
                      Expanded(child: _buildTimeField(subjectCode, 'endTime', 'End Time', Icons.stop_circle_outlined, () => _selectTime(_scheduleControllers[subjectCode]!['endTime']!))),
                      const SizedBox(width: 20),
                      Expanded(child: _buildDurationField(subjectCode)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildTimeField(subjectCode, 'date', 'Exam Date', Icons.calendar_today_rounded, () => _selectDate(_scheduleControllers[subjectCode]!['date']!)),
                      const SizedBox(height: 16),
                      _buildTimeField(subjectCode, 'startTime', 'Start Time', Icons.play_circle_outline_rounded, () => _selectTime(_scheduleControllers[subjectCode]!['startTime']!)),
                      const SizedBox(height: 16),
                      _buildTimeField(subjectCode, 'endTime', 'End Time', Icons.stop_circle_outlined, () => _selectTime(_scheduleControllers[subjectCode]!['endTime']!)),
                      const SizedBox(height: 16),
                      _buildDurationField(subjectCode),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField(String subjectCode, String fieldKey, String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          controller: _scheduleControllers[subjectCode]![fieldKey],
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87, fontSize: 14),
          decoration: _inputDecoration(label, icon),
        ),
      ),
    );
  }

  Widget _buildDurationField(String subjectCode) {
    return TextFormField(
      controller: _scheduleControllers[subjectCode]!['duration'],
      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87, fontSize: 14),
      decoration: _inputDecoration('Duration', Icons.timer_rounded),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!, fontSize: 12),
      prefixIcon: Icon(icon, color: const Color(0xFF4F46E5).withOpacity(0.7), size: 18),
      filled: true,
      fillColor: _isDarkMode ? const Color(0xFF111827).withOpacity(0.5) : Colors.grey[50]!,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  void dispose() {
    _scheduleControllers.forEach((_, controllers) => controllers.forEach((_, c) => c.dispose()));
    super.dispose();
  }
}
