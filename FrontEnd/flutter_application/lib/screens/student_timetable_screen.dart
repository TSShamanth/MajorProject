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
import '../../widgets/student_layout.dart';

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
      _currentUser = await _apiService.getMe(_institutionId!);
      
      if (_currentUser!.departmentId == null || _currentUser!.programme == null || _currentUser!.sem == null || _currentUser!.sectionId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

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

      if (mounted) {
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
      }
    } catch (e) {
      debugPrint('Error loading student timetable: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: 'Academic Timetable',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Timetable', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? _buildErrorState('User not found.')
              : _currentUser!.departmentId == null || _currentUser!.sectionId == null
                  ? _buildErrorState('Your profile is incomplete. Please ask an admin to assign your Department and Section.')
                  : _timetableEntries.isEmpty
                      ? _buildErrorState('No timetable found for your class.')
                      : _buildTimetableContent(),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded, size: 48, color: Color(0xFFF59E0B)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBar(),
          const SizedBox(height: 24),
          _buildTimetableGrid(),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, color: Color(0xFF4F46E5), size: 20),
          const SizedBox(width: 12),
          Text(
            '${_currentUser?.programme} • Semester ${_currentUser?.sem} • Section ${_currentUser?.sectionId}',
            style: const TextStyle(
              color: Color(0xFF4F46E5),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(180),
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey.shade100, width: 1),
              verticalInside: BorderSide(color: Colors.grey.shade100, width: 1),
            ),
            children: [
              // Header Row
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                children: [
                  const TableCell(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Text('TIME / DAY', 
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF6B7280), letterSpacing: 1),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  ..._workingDays.map((day) => TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Text(day.dayName.toUpperCase(), 
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1F2937), letterSpacing: 1),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )),
                ],
              ),
              // Time Slot Rows
              ..._timeSlots.map((slot) => TableRow(
                children: [
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(slot.startTime, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1F2937))),
                          const SizedBox(height: 4),
                          Container(width: 12, height: 1, color: Colors.grey.shade300),
                          const SizedBox(height: 4),
                          Text(slot.endTime, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ),
                  ..._workingDays.map((day) {
                    final entry = _timetableEntries.firstWhere(
                      (e) => e.day == day.dayName && e.timeSlotId == slot.id,
                      orElse: () => TimetableEntry(institutionId: '', departmentId: '', program: '', semester: '', sectionId: '', day: '', timeSlotId: '', courseCode: '', facultyUid: '', roomId: '', academicYear: ''),
                    );

                    if (entry.institutionId.isEmpty) {
                      return const TableCell(child: SizedBox(height: 100));
                    }

                    final course = _courses.firstWhere((c) => c.courseCode == entry.courseCode, orElse: () => Course(courseCode: '', courseName: 'Unknown', facultyUid: '', institutionId: '', program: '', semester: '', studentsEnrolled: [], totalClasses: ''));
                    final teacher = _faculty.firstWhere((f) => f.uid == entry.facultyUid, orElse: () => UserModel(uid: '', email: '', displayName: 'Unknown', role: 'faculty', name: 'Unknown'));
                    final room = _rooms.firstWhere((r) => r.id == entry.roomId, orElse: () => Room(id: '', name: 'N/A', capacity: 0, institutionId: ''));

                    return TableCell(
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.courseName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF4F46E5)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.person_rounded, size: 12, color: Color(0xFF6B7280)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    teacher.displayName,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF6B7280)),
                                const SizedBox(width: 4),
                                Text(
                                  'Room ${room.name}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                                ),
                              ],
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
