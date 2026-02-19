import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/models/exam_model.dart' as app_models;
import 'package:flutter_application/models/exam_schedule_entry.dart';
import 'package:intl/intl.dart'; // For date formatting

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

  // Controllers for each subject's schedule fields
  // Key: Subject Code, Value: Map of controllers (date, start, end, duration)
  final Map<String, Map<String, TextEditingController>> _scheduleControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchExamDetails();
  }

  Future<void> _fetchExamDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) {
        throw Exception('Institution ID not found.');
      }

      if (widget.examId != null) {
        // Fetch existing exam to edit its schedule
        final fetchedExam = await _apiService.getExamById(institutionId, widget.examId!);
        if (!mounted) return;
        setState(() {
          _exam = fetchedExam;
        });

        // Initialize controllers with existing schedule data
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
        // This screen is for editing schedules of existing exams.
        // If examId is null, it means no exam selected for scheduling.
        // A separate screen (e.g., create_exam_screen) would handle initial exam creation.
        _errorMessage = 'No exam selected for scheduling. Please select an exam from the dashboard.';
      }
    } catch (e) {
      if (!mounted) return;
      _errorMessage = 'Failed to load exam details: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSchedule() async {
    if (!mounted) return;
    final capturedContext = context; // Capture context here

    void showSnackBarMessage(String message, {bool isError = false}) {
      if (!capturedContext.mounted) return;
      ScaffoldMessenger.of(capturedContext).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: isError ? Theme.of(capturedContext).colorScheme.error : null),
      );
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) {
        throw Exception('Institution ID not found.');
      }
      if (_exam == null) {
        throw Exception('No exam to save schedule for.');
      }

      Map<String, ExamScheduleEntry> newSchedule = {};
      for (var subjectCode in _exam!.subjects) {
        final controllers = _scheduleControllers[subjectCode];
        if (controllers != null &&
            controllers['date']!.text.isNotEmpty &&
            controllers['startTime']!.text.isNotEmpty &&
            controllers['endTime']!.text.isNotEmpty &&
            controllers['duration']!.text.isNotEmpty) {
          newSchedule[subjectCode] = ExamScheduleEntry(
            date: controllers['date']!.text,
            startTime: controllers['startTime']!.text,
            endTime: controllers['endTime']!.text,
            duration: controllers['duration']!.text,
          );
        }
      }

      await _apiService.updateExamSchedule(institutionId, _exam!.id, newSchedule);
      showSnackBarMessage('Exam schedule updated successfully!');
      // Defer navigation until after the current frame is built
      if (capturedContext.mounted) { // Re-check mounted before scheduling the callback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (capturedContext.mounted) { // Re-check mounted inside the callback as well
            capturedContext.pop();
          }
        });
      }
    } catch (e) {
      _errorMessage = 'Failed to save schedule: $e';
      showSnackBarMessage(_errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper for Date Picker
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // Helper for Time Picker
  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final capturedContext = context; // Capture context here
    final TimeOfDay? picked = await showTimePicker(
      context: capturedContext, // Use captured context for the picker
      initialTime: TimeOfDay.now(),
    );
    if (!capturedContext.mounted) return; // Use captured context for the guard
    if (picked != null) {
      controller.text = picked.format(capturedContext); // Use captured context here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_exam != null ? 'Schedule for ${_exam!.name}' : 'Exam Schedule Editor'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _exam == null
                  ? const Center(child: Text('Please select an exam to schedule.'))
                  : ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        Text(
                          'Exam: ${_exam!.name}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          'Department: ${_exam!.departmentId}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Semester: ${_exam!.semester}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 20),
                        const Text('Subject-wise Schedule:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ..._exam!.subjects.map((subjectCode) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Subject: $subjectCode',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _scheduleControllers[subjectCode]!['date'],
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        labelText: 'Date (YYYY-MM-DD)',
                                        border: const OutlineInputBorder(),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.calendar_today),
                                          onPressed: () => _selectDate(context, _scheduleControllers[subjectCode]!['date']!),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _scheduleControllers[subjectCode]!['startTime'],
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        labelText: 'Start Time',
                                        border: const OutlineInputBorder(),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.access_time),
                                          onPressed: () => _selectTime(context, _scheduleControllers[subjectCode]!['startTime']!),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _scheduleControllers[subjectCode]!['endTime'],
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        labelText: 'End Time',
                                        border: const OutlineInputBorder(),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.access_time),
                                          onPressed: () => _selectTime(context, _scheduleControllers[subjectCode]!['endTime']!),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _scheduleControllers[subjectCode]!['duration'],
                                      decoration: const InputDecoration(
                                        labelText: 'Duration (e.g., "3 hours", "90 mins")',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _saveSchedule,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50), // Make button full width
                          ),
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Schedule'),
                        ),
                      ],
                    ),
    );
  }

  @override
  void dispose() {
    _scheduleControllers.forEach((subjectCode, controllers) {
      controllers.forEach((key, controller) {
        controller.dispose();
      });
    });
    super.dispose();
  }
}
