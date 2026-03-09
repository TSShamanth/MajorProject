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
import '../widgets/faculty_layout.dart';

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
  bool _isDarkMode = false;

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
        _apiService.getCourses(_institutionId!, _currentUser!.departmentId!),
        _apiService.getRooms(_institutionId!),
      ]);

      if (mounted) {
        setState(() {
          _timeSlots = results[0] as List<TimeSlot>;
          _timeSlots.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
          _workingDays = (results[1] as List<WorkingDay>).where((d) => d.isWorking).toList();
          _facultyEntries = results[2] as List<TimetableEntry>;
          _courses = results[3] as List<Course>;
          _rooms = results[4] as List<Room>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading faculty timetable: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);

    return FacultyLayout(
      title: 'Teaching Schedule',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Timetable', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(child: Text('User not found.'))
              : _currentUser!.departmentId == null
                  ? _buildIncompleteProfile()
                  : Padding(
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
                                    'Weekly Timetable',
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'View and manage your weekly lecture assignments',
                                    style: TextStyle(fontSize: 14, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: _loadFacultyTimetable,
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Refresh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: _facultyEntries.isEmpty
                                ? _buildEmptyState()
                                : _buildTimetableGrid(),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildIncompleteProfile() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 64),
            const SizedBox(height: 20),
            const Text(
              'Profile Incomplete',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Your profile is missing department information. Please contact the administrator to assign your department so you can view your schedule.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: _isDarkMode ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'No Teaching Assignments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any classes scheduled yet.',
            style: TextStyle(color: _isDarkMode ? Colors.grey[500] : Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableGrid() {
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final headerColor = _isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC);

    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(180),
              border: TableBorder.all(color: borderColor, width: 0.5),
              children: [
                // Header Row
                TableRow(
                  decoration: BoxDecoration(color: headerColor),
                  children: [
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        child: Text('Time / Day', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF4F46E5))),
                      ),
                    ),
                    ..._workingDays.map((day) => TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        child: Text(day.dayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    )),
                  ],
                ),
                // Data Rows
                ..._timeSlots.map((slot) => TableRow(
                  children: [
                    // Time Slot Cell
                    TableCell(
                      child: Container(
                        height: 100,
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(slot.startTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(slot.endTime, style: TextStyle(color: _isDarkMode ? Colors.grey[500] : Colors.grey[500], fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    // Working Day Cells
                    ..._workingDays.map((day) {
                      final entry = _facultyEntries.firstWhere(
                        (e) => e.day == day.dayName && e.timeSlotId == slot.id,
                        orElse: () => TimetableEntry(institutionId: '', departmentId: '', program: '', semester: '', sectionId: '', day: '', timeSlotId: '', courseCode: '', facultyUid: '', roomId: '', academicYear: ''),
                      );

                      if (entry.institutionId.isEmpty) {
                        return const TableCell(child: SizedBox(height: 100));
                      }

                      final course = _courses.firstWhere(
                        (c) => c.courseCode == entry.courseCode, 
                        orElse: () => Course(courseCode: '', courseName: 'Unknown Course', facultyUid: '', institutionId: '', program: '', semester: '', studentsEnrolled: [], totalClasses: '')
                      );
                      final room = _rooms.firstWhere(
                        (r) => r.id == entry.roomId, 
                        orElse: () => Room(id: '', name: 'N/A', capacity: 0, institutionId: '')
                      );

                      return TableCell(
                        child: Container(
                          height: 100,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                course.courseName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4F46E5)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 10, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Room: ${room.name}',
                                      style: TextStyle(fontSize: 10, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.school_outlined, size: 10, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${entry.program} S${entry.semester}',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _isDarkMode ? Colors.grey[300] : Colors.grey[700]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
      ),
    );
  }
}
