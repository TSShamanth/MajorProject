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

class StudentTimetableScreen extends StatefulWidget {
  const StudentTimetableScreen({super.key});

  @override
  State<StudentTimetableScreen> createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends State<StudentTimetableScreen> {
  final ApiService _apiService = ApiService();
  final TimetableService _timetableService = TimetableService();

  List<TimeSlot> _timeSlots = [];
  List<WorkingDay> _workingDays = [];
  List<TimetableEntry> _timetableEntries = [];
  List<Course> _courses = [];
  List<Room> _rooms = [];
  List<UserModel> _faculty = [];
  
  bool _isLoading = true;
  String? _institutionId;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (_institutionId == null) return;

    try {
      // 1. Get current user
      _currentUser = await _apiService.getMe(_institutionId!);
      
      if (_currentUser!.departmentId == null || _currentUser!.programme == null || _currentUser!.sem == null || _currentUser!.sectionId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. Fetch all necessary data
      final results = await Future.wait([
        _timetableService.getTimeSlots(_institutionId!),
        _timetableService.getWorkingDays(_institutionId!),
        _timetableService.getTimetableForClass(
          _institutionId!,
          _currentUser!.departmentId!,
          _currentUser!.programme!,
          _currentUser!.sem!,
          _currentUser!.sectionId!,
        ),
        _apiService.getCourses(_institutionId!, _currentUser!.departmentId!),
        _apiService.getRooms(_institutionId!),
        _apiService.getUsers(_institutionId!),
      ]);

      setState(() {
        _timeSlots = results[0] as List<TimeSlot>;
        _timeSlots.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
        _workingDays = (results[1] as List<WorkingDay>).where((d) => d.isWorking).toList();
        _timetableEntries = results[2] as List<TimetableEntry>;
        _courses = results[3] as List<Course>;
        _rooms = results[4] as List<Room>;
        _faculty = (results[5] as List<UserModel>).where((u) => u.role == 'faculty').toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading student timetable: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _currentUser == null
            ? const Center(child: Text('User not found.'))
            : _currentUser!.departmentId == null || _currentUser!.sectionId == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Your profile is incomplete. Please ask an admin to assign your Department and Section.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.orange),
                      ),
                    ),
                  )
                : _timetableEntries.isEmpty
                    ? const Center(child: Text('No timetable found for your class.'))
                    : _buildTimetableGrid();
  }

  Widget _buildTimetableGrid() {
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
              // Header Row
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  const TableCell(child: Padding(padding: EdgeInsets.all(12), child: Text('Time / Day', style: TextStyle(fontWeight: FontWeight.bold)))),
                  ..._workingDays.map((day) => TableCell(child: Padding(padding: EdgeInsets.all(12), child: Text(day.dayName, style: const TextStyle(fontWeight: FontWeight.bold))))),
                ],
              ),
              // Time Slot Rows
              ..._timeSlots.map((slot) => TableRow(
                children: [
                  TableCell(child: Padding(padding: EdgeInsets.all(12), child: Text('${slot.startTime}\n-\n${slot.endTime}', textAlign: TextAlign.center))),
                  ..._workingDays.map((day) {
                    final entry = _timetableEntries.firstWhere(
                      (e) => e.day == day.dayName && e.timeSlotId == slot.id,
                      orElse: () => TimetableEntry(institutionId: '', departmentId: '', program: '', semester: '', sectionId: '', day: '', timeSlotId: '', courseCode: '', facultyUid: '', roomId: '', academicYear: ''),
                    );

                    if (entry.institutionId.isEmpty) {
                      return const TableCell(child: SizedBox(height: 80));
                    }

                    final course = _courses.firstWhere((c) => c.courseCode == entry.courseCode, orElse: () => Course(courseCode: '', courseName: 'Unknown', facultyUid: '', institutionId: '', program: '', semester: '', studentsEnrolled: [], totalClasses: ''));
                    final teacher = _faculty.firstWhere((f) => f.uid == entry.facultyUid, orElse: () => UserModel(uid: '', email: '', displayName: 'Unknown', role: 'faculty', name: 'Unknown'));
                    final room = _rooms.firstWhere((r) => r.id == entry.roomId, orElse: () => Room(id: '', name: 'N/A', capacity: 0, institutionId: ''));

                    return TableCell(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        color: Colors.indigo.withOpacity(0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.courseName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.indigo),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              teacher.displayName,
                              style: const TextStyle(fontSize: 10),
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
