import 'package:flutter/material.dart';
import 'package:flutter_application/models/course_model.dart';
import 'package:flutter_application/models/room_model.dart';
import 'package:flutter_application/models/time_slot_model.dart';
import 'package:flutter_application/models/timetable_entry_model.dart';
import 'package:flutter_application/models/working_day_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/services/timetable_service.dart';

class FacultyTimetableScreen extends StatefulWidget {
  const FacultyTimetableScreen({super.key});

  @override
  State<FacultyTimetableScreen> createState() => _FacultyTimetableScreenState();
}

class _FacultyTimetableScreenState extends State<FacultyTimetableScreen> {
  final ApiService _apiService = ApiService();
  final TimetableService _timetableService = TimetableService();

  List<TimeSlot> _timeSlots = [];
  List<WorkingDay> _workingDays = [];
  List<TimetableEntry> _facultyEntries = [];
  List<Course> _courses = [];
  List<Room> _rooms = [];

  bool _isLoading = true;
  String? _institutionId;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadFacultyTimetable();
  }

  Future<void> _loadFacultyTimetable() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (_institutionId == null) return;

    try {
      _currentUser = await _apiService.getMe(_institutionId!);
      
      if (_currentUser!.departmentId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final results = await Future.wait([
        _timetableService.getTimeSlots(_institutionId!),
        _timetableService.getWorkingDays(_institutionId!),
        _timetableService.getTimetableForFaculty(_institutionId!, _currentUser!.uid),
        _apiService.getCourses(_institutionId!, _currentUser!.departmentId!), // Need department for courses
        _apiService.getRooms(_institutionId!),
      ]);

      setState(() {
        _timeSlots = results[0] as List<TimeSlot>;
        _timeSlots.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
        _workingDays = (results[1] as List<WorkingDay>).where((d) => d.isWorking).toList();
        _facultyEntries = results[2] as List<TimetableEntry>;
        _courses = results[3] as List<Course>;
        _rooms = results[4] as List<Room>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading faculty timetable: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Teaching Schedule')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(child: Text('User not found.'))
              : _currentUser!.departmentId == null
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'Your profile is incomplete. Please ask an admin to assign your Department.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.orange),
                        ),
                      ),
                    )
                  : _facultyEntries.isEmpty
                      ? const Center(child: Text('No teaching assignments found for your account.'))
                      : _buildFacultyGrid(),
    );
  }

  Widget _buildFacultyGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(150),
            border: TableBorder.all(color: Colors.grey.shade300),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  const TableCell(child: Padding(padding: EdgeInsets.all(12), child: Text('Time / Day', style: TextStyle(fontWeight: FontWeight.bold)))),
                  ..._workingDays.map((day) => TableCell(child: Padding(padding: EdgeInsets.all(12), child: Text(day.dayName, style: const TextStyle(fontWeight: FontWeight.bold))))),
                ],
              ),
              ..._timeSlots.map((slot) => TableRow(
                children: [
                  TableCell(child: Padding(padding: EdgeInsets.all(12), child: Text('${slot.startTime} - ${slot.endTime}', textAlign: TextAlign.center))),
                  ..._workingDays.map((day) {
                    final entry = _facultyEntries.firstWhere(
                      (e) => e.day == day.dayName && e.timeSlotId == slot.id,
                      orElse: () => TimetableEntry(institutionId: '', departmentId: '', program: '', semester: '', sectionId: '', day: '', timeSlotId: '', courseCode: '', facultyUid: '', roomId: '', academicYear: ''),
                    );

                    if (entry.institutionId.isEmpty) {
                      return const TableCell(child: SizedBox(height: 80));
                    }

                    final course = _courses.firstWhere((c) => c.courseCode == entry.courseCode, orElse: () => Course(courseCode: '', courseName: 'Unknown', facultyUid: '', institutionId: '', program: '', semester: '', studentsEnrolled: [], totalClasses: ''));
                    final room = _rooms.firstWhere((r) => r.id == entry.roomId, orElse: () => Room(id: '', name: 'N/A', capacity: 0, institutionId: ''));

                    return TableCell(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        color: Colors.teal.withOpacity(0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.courseName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.teal),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${entry.program} Sem ${entry.semester}',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Room: ${room.name}',
                              style: const TextStyle(fontSize: 9, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}
