import 'package:flutter/material.dart';
import 'package:flutter_application/models/course_model.dart';
import 'package:flutter_application/models/department_model.dart';
import 'package:flutter_application/models/room_model.dart';
import 'package:flutter_application/models/section_model.dart';
import 'package:flutter_application/models/time_slot_model.dart';
import 'package:flutter_application/models/timetable_entry_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/models/working_day_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/services/timetable_service.dart';
import 'package:flutter_application/widgets/admin_layout.dart';

class TimetableGenerationScreen extends StatefulWidget {
  const TimetableGenerationScreen({super.key});

  @override
  State<TimetableGenerationScreen> createState() => _TimetableGenerationScreenState();
}

class _TimetableGenerationScreenState extends State<TimetableGenerationScreen> {
  final ApiService _apiService = ApiService();
  final TimetableService _timetableService = TimetableService();

  String? _institutionId;
  List<Department> _departments = [];
  List<Section> _sections = [];
  List<Course> _courses = [];
  List<Room> _rooms = [];
  List<UserModel> _faculty = [];
  List<TimeSlot> _timeSlots = [];
  List<WorkingDay> _workingDays = [];
  List<TimetableEntry> _timetableEntries = [];

  String? _selectedDepartmentId;
  String? _selectedProgram;
  String? _selectedSemester;
  String? _selectedSectionId;
  String _academicYear = '2025-26';

  bool _isLoading = true;
  bool _isGridVisible = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (_institutionId != null) {
      try {
        final results = await Future.wait([
          _apiService.getDepartments(_institutionId!),
          _apiService.getRooms(_institutionId!),
          _apiService.getUsers(_institutionId!),
          _timetableService.getTimeSlots(_institutionId!),
          _timetableService.getWorkingDays(_institutionId!),
        ]);

        setState(() {
          _departments = results[0] as List<Department>;
          _rooms = results[1] as List<Room>;
          final allUsers = results[2] as List<UserModel>;
          _faculty = allUsers.where((u) => u.role == 'faculty').toList();
          _timeSlots = results[3] as List<TimeSlot>;
          _timeSlots.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
          _workingDays = (results[4] as List<WorkingDay>).where((d) => d.isWorking).toList();
          // Sort working days if needed
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        debugPrint('Error loading initial data: $e');
      }
    }
  }

  Future<void> _onDepartmentChanged(String? id) async {
    setState(() {
      _selectedDepartmentId = id;
      _selectedSectionId = null;
      _sections = [];
      _courses = [];
      _isGridVisible = false;
    });
    if (id != null) {
      final results = await Future.wait([
        _apiService.getSections(_institutionId!, id),
        _apiService.getCourses(_institutionId!, id),
      ]);
      setState(() {
        _sections = results[0] as List<Section>;
        _courses = results[1] as List<Course>;
      });
    }
  }

  Future<void> _fetchTimetable() async {
    if (_selectedDepartmentId == null || _selectedProgram == null || _selectedSemester == null || _selectedSectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all filters')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final entries = await _timetableService.getTimetableForClass(
        _institutionId!,
        _selectedDepartmentId!,
        _selectedProgram!,
        _selectedSemester!,
        _selectedSectionId!,
      );
      setState(() {
        _timetableEntries = entries;
        _isGridVisible = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching timetable: $e');
    }
  }

  void _showAssignmentDialog(WorkingDay day, TimeSlot slot, TimetableEntry? existingEntry) {
    String? selectedCourseCode = existingEntry?.courseCode;
    String? selectedFacultyUid = existingEntry?.facultyUid;
    String? selectedRoomId = existingEntry?.roomId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${existingEntry == null ? 'Assign' : 'Edit'} Slot: ${day.dayName}, ${slot.startTime} - ${slot.endTime}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCourseCode,
                decoration: const InputDecoration(labelText: 'Subject (Course)'),
                items: _courses.map((c) => DropdownMenuItem(value: c.courseCode, child: Text(c.courseName))).toList(),
                onChanged: (val) => setDialogState(() => selectedCourseCode = val),
              ),
              DropdownButtonFormField<String>(
                value: selectedFacultyUid,
                decoration: const InputDecoration(labelText: 'Faculty'),
                items: _faculty.map((f) => DropdownMenuItem(value: f.uid, child: Text(f.displayName))).toList(),
                onChanged: (val) => setDialogState(() => selectedFacultyUid = val),
              ),
              DropdownButtonFormField<String>(
                value: selectedRoomId,
                decoration: const InputDecoration(labelText: 'Room'),
                items: _rooms.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
                onChanged: (val) => setDialogState(() => selectedRoomId = val),
              ),
            ],
          ),
          actions: [
            if (existingEntry != null)
              TextButton(
                onPressed: () async {
                  await _timetableService.deleteTimetable(_institutionId!, existingEntry.id!);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _fetchTimetable();
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedCourseCode == null || selectedFacultyUid == null || selectedRoomId == null) return;
                
                final entry = TimetableEntry(
                  id: existingEntry?.id,
                  institutionId: _institutionId!,
                  departmentId: _selectedDepartmentId!,
                  program: _selectedProgram!,
                  semester: _selectedSemester!,
                  sectionId: _selectedSectionId!,
                  day: day.dayName,
                  timeSlotId: slot.id!,
                  courseCode: selectedCourseCode!,
                  facultyUid: selectedFacultyUid!,
                  roomId: selectedRoomId!,
                  academicYear: _academicYear,
                );

                try {
                  if (existingEntry == null) {
                    await _timetableService.assignTimetable(_institutionId!, entry);
                  } else {
                    await _timetableService.updateTimetable(_institutionId!, entry);
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _fetchTimetable();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Timetable Management',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilters(),
                  const SizedBox(height: 32),
                  if (_isGridVisible) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Weekly Timetable Grid',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: _fetchTimetable,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Grid'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4F46E5),
                            side: const BorderSide(color: Color(0xFF4F46E5)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTimetableGrid(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDepartmentId,
                    decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                    items: _departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                    onChanged: _onDepartmentChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedProgram,
                    decoration: const InputDecoration(labelText: 'Program', border: OutlineInputBorder()),
                    items: ['B.Tech', 'M.Tech', 'B.Sc', 'M.Sc', 'MBA'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => _selectedProgram = val),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSemester,
                    decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
                    items: List.generate(8, (index) => (index + 1).toString()).map((s) => DropdownMenuItem(value: s, child: Text('Sem $s'))).toList(),
                    onChanged: (val) => setState(() => _selectedSemester = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSectionId,
                    decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder()),
                    items: _sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (val) => setState(() => _selectedSectionId = val),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _academicYear,
                    decoration: const InputDecoration(labelText: 'Academic Year', border: OutlineInputBorder()),
                    onChanged: (val) => _academicYear = val,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _fetchTimetable,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Generate / Load Grid'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableGrid() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
          border: TableBorder.all(color: const Color(0xFFE5E7EB)),
          columns: [
            const DataColumn(label: Text('Time / Day', style: TextStyle(fontWeight: FontWeight.bold))),
            ..._workingDays.map((day) => DataColumn(label: Text(day.dayName, style: const TextStyle(fontWeight: FontWeight.bold)))),
          ],
          rows: _timeSlots.map((slot) {
            return DataRow(
              cells: [
                DataCell(Text('${slot.startTime}\n-\n${slot.endTime}', textAlign: TextAlign.center)),
                ..._workingDays.map((day) {
                  final entry = _timetableEntries.firstWhere(
                    (e) => e.day == day.dayName && e.timeSlotId == slot.id,
                    orElse: () => TimetableEntry(
                      institutionId: '', departmentId: '', program: '', semester: '', sectionId: '', day: '', timeSlotId: '', courseCode: '', facultyUid: '', roomId: '', academicYear: ''
                    ),
                  );

                  final bool exists = entry.institutionId.isNotEmpty;

                  return DataCell(
                    InkWell(
                      onTap: () => _showAssignmentDialog(day, slot, exists ? entry : null),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(
                          color: exists ? const Color(0xFFEEF2FF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: exists
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _courses.firstWhere((c) => c.courseCode == entry.courseCode, orElse: () => Course(courseCode: '', courseName: 'Unknown', facultyUid: '', institutionId: '', program: '', semester: '', studentsEnrolled: [], totalClasses: '')).courseName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF4F46E5)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _faculty.firstWhere((f) => f.uid == entry.facultyUid, orElse: () => UserModel(uid: '', email: '', displayName: 'Unknown', role: 'faculty', name: 'Unknown')).displayName,
                                    style: const TextStyle(fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Room: ${_rooms.firstWhere((r) => r.id == entry.roomId, orElse: () => Room(id: '', name: 'N/A', capacity: 0, institutionId: '')).name}',
                                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                                  ),
                                ],
                              )
                            : const Center(child: Icon(Icons.add, color: Colors.grey, size: 18)),
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
