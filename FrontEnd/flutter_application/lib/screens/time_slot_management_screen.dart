import 'package:flutter/material.dart';
import 'package:flutter_application/models/time_slot_model.dart';
import 'package:flutter_application/services/timetable_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/widgets/admin_layout.dart';

class TimeSlotManagementScreen extends StatefulWidget {
  const TimeSlotManagementScreen({super.key});

  @override
  State<TimeSlotManagementScreen> createState() => _TimeSlotManagementScreenState();
}

class _TimeSlotManagementScreenState extends State<TimeSlotManagementScreen> {
  final TimetableService _timetableService = TimetableService();
  List<TimeSlot> _timeSlots = [];
  bool _isLoading = true;
  String? _institutionId;

  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (_institutionId != null) {
      _fetchTimeSlots();
    }
  }

  Future<void> _fetchTimeSlots() async {
    if (_institutionId == null) return;
    setState(() => _isLoading = true);
    try {
      final slots = await _timetableService.getTimeSlots(_institutionId!);
      slots.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
      setState(() {
        _timeSlots = slots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _addTimeSlot() async {
    if (_institutionId == null) return;
    
    final slotNumber = _timeSlots.isEmpty ? 1 : _timeSlots.last.slotNumber + 1;
    final newSlot = TimeSlot(
      slotNumber: slotNumber,
      startTime: _startTimeController.text,
      endTime: _endTimeController.text,
      institutionId: _institutionId!,
    );

    try {
      await _timetableService.createTimeSlot(_institutionId!, newSlot);
      _startTimeController.clear();
      _endTimeController.clear();
      _fetchTimeSlots();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteTimeSlot(String id) async {
    try {
      await _timetableService.deleteTimeSlot(_institutionId!, id);
      _fetchTimeSlots();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddTimeSlotDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Time Slot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _startTimeController,
              decoration: const InputDecoration(labelText: 'Start Time (e.g. 09:00 AM)'),
            ),
            TextField(
              controller: _endTimeController,
              decoration: const InputDecoration(labelText: 'End Time (e.g. 10:00 AM)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _addTimeSlot();
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Time Slot Management',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Defined Time Slots',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddTimeSlotDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Slot'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
                            columns: const [
                              DataColumn(label: Text('Slot #', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Start Time', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('End Time', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _timeSlots.map((slot) => DataRow(
                              cells: [
                                DataCell(Text(slot.slotNumber.toString())),
                                DataCell(Text(slot.startTime)),
                                DataCell(Text(slot.endTime)),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteTimeSlot(slot.id!),
                                  ),
                                ),
                              ],
                            )).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
