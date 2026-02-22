import 'package:flutter/material.dart';
import 'package:flutter_application/models/working_day_model.dart';
import 'package:flutter_application/services/timetable_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/widgets/admin_layout.dart';

class WorkingDayManagementScreen extends StatefulWidget {
  const WorkingDayManagementScreen({super.key});

  @override
  State<WorkingDayManagementScreen> createState() => _WorkingDayManagementScreenState();
}

class _WorkingDayManagementScreenState extends State<WorkingDayManagementScreen> {
  final TimetableService _timetableService = TimetableService();
  List<WorkingDay> _workingDays = [];
  bool _isLoading = true;
  String? _institutionId;

  final List<String> _allDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (_institutionId != null) {
      _fetchWorkingDays();
    }
  }

  Future<void> _fetchWorkingDays() async {
    if (_institutionId == null) return;
    setState(() => _isLoading = true);
    try {
      final days = await _timetableService.getWorkingDays(_institutionId!);
      
      // If no days defined, create defaults
      if (days.isEmpty) {
        // Re-fetch or use local if we decided to save them. 
        // Let's just create them in backend if empty.
        await _initializeDefaultDays();
      } else {
        // Sort according to _allDays
        days.sort((a, b) => _allDays.indexOf(a.dayName).compareTo(_allDays.indexOf(b.dayName)));
        setState(() {
          _workingDays = days;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _initializeDefaultDays() async {
    for (var dayName in _allDays) {
      final isWorking = dayName != 'Sunday';
      final newDay = WorkingDay(
        dayName: dayName,
        isWorking: isWorking,
        institutionId: _institutionId!,
      );
      // This is a bit slow doing it one by one, but fine for 7 items
      // In production, use a bulk save API
      await _timetableService.createWorkingDay(_institutionId!, newDay);
    }
    _fetchWorkingDays();
  }

  Future<void> _toggleWorkingDay(WorkingDay day) async {
    final updatedDay = WorkingDay(
      id: day.id,
      dayName: day.dayName,
      isWorking: !day.isWorking,
      institutionId: day.institutionId,
    );

    try {
      await _timetableService.updateWorkingDay(_institutionId!, updatedDay);
      _fetchWorkingDays();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Working Days Management',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Define Institution Working Days',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enable or disable days that are active for classes.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _workingDays.length,
                      itemBuilder: (context, index) {
                        final day = _workingDays[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          child: SwitchListTile(
                            title: Text(
                              day.dayName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(day.isWorking ? 'Working Day' : 'Holiday / Weekend'),
                            value: day.isWorking,
                            onChanged: (_) => _toggleWorkingDay(day),
                            activeColor: const Color(0xFF4F46E5),
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
