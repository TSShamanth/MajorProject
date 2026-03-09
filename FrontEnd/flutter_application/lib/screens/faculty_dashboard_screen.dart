import 'package:flutter/material.dart';
import 'package:flutter_application/models/announcement_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/models/attendance_log_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/services/announcement_service.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../widgets/faculty_layout.dart';
import '../models/course_model.dart';
import '../models/timetable_entry_model.dart';
import '../models/time_slot_model.dart';
import '../models/room_model.dart';
import '../services/timetable_service.dart';

class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen> {
  final ApiService _apiService = ApiService();
  final AnnouncementService _announcementService = AnnouncementService();
  UserModel? _currentUser;
  AttendanceLog? _activeLog;
  String? _institutionId;
  bool _isLoading = true;
  bool _isDarkMode = false;
  bool _isClocking = false;
  Timer? _clockInTimer;
  String _clockedInDuration = '00:00:00';

  // Stats
  int _menteeCount = 0;
  int _courseCount = 0;
  int _pendingApprovals = 0;

  // Schedule
  List<TimetableEntry> _todaySchedule = [];
  List<TimeSlot> _allTimeSlots = [];
  List<Course> _allCourses = [];
  List<Room> _allRooms = [];
  bool _isLoadingSchedule = true;

  // Announcements
  List<AnnouncementModel> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _clockInTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      _institutionId = await SessionManager.getInstitutionId();
      if (_institutionId == null) return;

      final user = await _apiService.getMe(_institutionId!);
      final announcements = await _announcementService.getAnnouncements(
        _institutionId!,
        role: user.role,
        departmentId: user.departmentId,
      );
      
      AttendanceLog? activeLog;
      if (user.attendanceStatus == 'Clocked-in') {
        final history = await _apiService.getAttendanceHistory(_institutionId!);
        if (history.isNotEmpty && history.first.clockOutTime == null) {
          activeLog = history.first;
        }
      }

      if (mounted) {
        setState(() {
          _currentUser = user;
          _activeLog = activeLog;
          _announcements = announcements.take(5).toList();
          _isLoading = false;
        });
        
        if (activeLog != null) {
          _startClockTimer();
        }
      }

      await Future.wait([
        _fetchStats(),
        _fetchTodaySchedule(),
      ]);
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startClockTimer() {
    _clockInTimer?.cancel();
    
    // Initial update
    _updateDuration();
    
    _clockInTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeLog != null) {
        _updateDuration();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateDuration() {
    if (_activeLog == null) return;
    
    final now = DateTime.now();
    final diff = now.difference(_activeLog!.clockInTime);
    
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    
    if (mounted) {
      setState(() {
        _clockedInDuration = '$hours:$minutes:$seconds';
      });
    }
  }

  Future<void> _fetchStats() async {
    if (_institutionId == null || _currentUser == null) return;
    try {
      final allUsers = await _apiService.getUsers(_institutionId!);
      final mentees = allUsers.where((u) => u.role == 'student' && u.mentorName == _currentUser!.displayName).toList();
      
      if (mounted) {
        setState(() {
          _menteeCount = mentees.length;
          _pendingApprovals = 3; // Placeholder
        });
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  Future<void> _fetchTodaySchedule() async {
    if (_institutionId == null || _currentUser == null) return;
    try {
      final timetableService = TimetableService();
      final now = DateTime.now();
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final todayName = days[now.weekday - 1];

      final results = await Future.wait([
        timetableService.getTimeSlots(_institutionId!),
        timetableService.getTimetableForFaculty(_institutionId!, _currentUser!.uid),
        if (_currentUser!.departmentId != null)
          _apiService.getCourses(_institutionId!, _currentUser!.departmentId!)
        else
          Future.value(<Course>[]),
        _apiService.getRooms(_institutionId!),
      ]);

      if (mounted) {
        setState(() {
          _allTimeSlots = results[0] as List<TimeSlot>;
          final allEntries = results[1] as List<TimetableEntry>;
          _todaySchedule = allEntries.where((e) => e.day == todayName).toList();
          _todaySchedule.sort((a, b) {
            final slotA = _allTimeSlots.firstWhere((s) => s.id == a.timeSlotId, orElse: () => TimeSlot(id: '', startTime: '00:00', endTime: '00:00', slotNumber: 0, institutionId: ''));
            final slotB = _allTimeSlots.firstWhere((s) => s.id == b.timeSlotId, orElse: () => TimeSlot(id: '', startTime: '00:00', endTime: '00:00', slotNumber: 0, institutionId: ''));
            return slotA.startTime.compareTo(slotB.startTime);
          });
          _allCourses = results[2] as List<Course>;
          _courseCount = _allCourses.length;
          _allRooms = results[3] as List<Room>;
          _isLoadingSchedule = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
      if (mounted) setState(() => _isLoadingSchedule = false);
    }
  }

  Future<void> _handleClockAction() async {
    if (_institutionId == null || _currentUser == null) return;

    setState(() => _isClocking = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      Position position = await Geolocator.getCurrentPosition();

      UserModel updatedUser;
      bool isClockingIn = _currentUser!.attendanceStatus != 'Clocked-in';

      if (isClockingIn) {
        updatedUser = await _apiService.clockIn(
          _institutionId!, 
          position.latitude, 
          position.longitude
        );
      } else {
        updatedUser = await _apiService.clockOut(
          _institutionId!, 
          position.latitude, 
          position.longitude
        );
      }

      AttendanceLog? activeLog;
      if (updatedUser.attendanceStatus == 'Clocked-in') {
        final history = await _apiService.getAttendanceHistory(_institutionId!);
        if (history.isNotEmpty && history.first.clockOutTime == null) {
          activeLog = history.first;
        }
      } else {
        _clockInTimer?.cancel();
        _clockedInDuration = '00:00:00';
      }

      if (mounted) {
        setState(() {
          _currentUser = updatedUser;
          _activeLog = activeLog;
          _isClocking = false;
        });

        if (activeLog != null) {
          _startClockTimer();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isClockingIn ? 'Clocked in successfully!' : 'Clocked out successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Clock action error: $e');
      if (mounted) {
        setState(() => _isClocking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return FacultyLayout(
      title: 'Dashboard',
      child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 768;
                final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1200;
                final padding = isMobile ? 16.0 : 24.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      Text(
                        'Welcome back, ${_currentUser?.displayName ?? 'Faculty'}!',
                        style: TextStyle(
                          fontSize: isMobile ? 24 : 28,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Here is what is happening in your classes today.',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Attendance Horizontal Section
                      _buildAttendanceSection(isMobile),
                      const SizedBox(height: 24),

                      // Stats Row
                      _buildStatsRow(isMobile, isTablet),
                      const SizedBox(height: 24),

                      // Main Content
                      if (isMobile) ...[
                        _buildTodayScheduleCard(),
                        const SizedBox(height: 20),
                        _buildRecentAnnouncements(),
                        const SizedBox(height: 20),
                        _buildQuickActions(),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildTodayScheduleCard(),
                                  const SizedBox(height: 20),
                                  _buildRecentAnnouncements(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  _buildQuickActions(),
                                  const SizedBox(height: 20),
                                  _buildRecentActivity(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAttendanceSection(bool isMobile) {
    final isClockedIn = _currentUser?.attendanceStatus == 'Clocked-in';
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile 
        ? Column(
            children: [
              _buildAttendanceInfo(isClockedIn),
              const SizedBox(height: 16),
              _buildClockInOutButton(fullWidth: true),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAttendanceInfo(isClockedIn),
              _buildClockInOutButton(),
            ],
          ),
    );
  }

  Widget _buildAttendanceInfo(bool isClockedIn) {
    final todayName = DateFormat('EEEE').format(DateTime.now());
    final todayDate = DateFormat('MMM dd').format(DateTime.now());
    final statusColor = isClockedIn ? const Color(0xFF10B981) : Colors.grey;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isClockedIn ? Icons.timer_rounded : Icons.timer_off_rounded,
            color: statusColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  isClockedIn ? 'Active Session' : 'Work Shift',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                if (isClockedIn) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isClockedIn ? _clockedInDuration : '00:00:00',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isClockedIn ? const Color(0xFF4F46E5) : (_isDarkMode ? Colors.white : Colors.black),
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '$todayName, $todayDate',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.grey[500] : Colors.grey[500],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClockInOutButton({bool fullWidth = false}) {
    bool isClockedIn = _currentUser?.attendanceStatus == 'Clocked-in';
    
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: InkWell(
        onTap: _isClocking ? null : _handleClockAction,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isClockedIn 
                ? Colors.red.withOpacity(0.1) 
                : const Color(0xFF4F46E5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isClockedIn 
                  ? Colors.red.withOpacity(0.2) 
                  : const Color(0xFF4F46E5).withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isClocking)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF4F46E5))),
                )
              else
                Icon(
                  isClockedIn ? Icons.logout_rounded : Icons.login_rounded,
                  size: 20,
                  color: isClockedIn ? Colors.red : const Color(0xFF4F46E5),
                ),
              const SizedBox(width: 10),
              Text(
                isClockedIn ? 'Clock Out' : 'Clock In',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isClockedIn ? Colors.red : const Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isMobile, bool isTablet) {
    final stats = [
      {'label': 'Total Mentees', 'value': _menteeCount.toString(), 'icon': Icons.group_rounded, 'color': const Color(0xFF4F46E5)},
      {'label': 'My Courses', 'value': _courseCount.toString(), 'icon': Icons.book_rounded, 'color': const Color(0xFF10B981)},
      {'label': 'Today\'s Classes', 'value': _todaySchedule.length.toString(), 'icon': Icons.calendar_today_rounded, 'color': const Color(0xFF8B5CF6)},
      {'label': 'Pending Approvals', 'value': _pendingApprovals.toString(), 'icon': Icons.pending_actions_rounded, 'color': const Color(0xFFF59E0B)},
    ];

    if (isMobile) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) => _buildStatCard(stats[index]),
      );
    }

    return Row(
      children: stats.map((stat) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: stat == stats.last ? 0 : 16),
          child: _buildStatCard(stat),
        ),
      )).toList(),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (stat['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            stat['value'] as String,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          Text(
            stat['label'] as String,
            style: TextStyle(
              fontSize: 13,
              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayScheduleCard() {
    return _buildCard(
      title: 'Today\'s Schedule',
      icon: Icons.access_time_filled_rounded,
      color: const Color(0xFF4F46E5),
      child: _isLoadingSchedule 
          ? const Center(child: CircularProgressIndicator())
          : _todaySchedule.isEmpty 
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('No classes today. Enjoy your day!', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _todaySchedule.length,
                  separatorBuilder: (context, index) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final entry = _todaySchedule[index];
                    final slot = _allTimeSlots.firstWhere((s) => s.id == entry.timeSlotId, orElse: () => TimeSlot(id: '', startTime: '--', endTime: '--', slotNumber: 0, institutionId: ''));
                    final room = _allRooms.firstWhere((r) => r.id == entry.roomId, orElse: () => Room(id: '', name: entry.roomId, capacity: 0, institutionId: ''));
                    
                    return Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(slot.startTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(slot.endTime, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.courseCode, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              Text('Room: ${room.name}', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${entry.program} S${entry.semester}',
                            style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildRecentAnnouncements() {
    return _buildCard(
      title: 'Announcements',
      icon: Icons.campaign_rounded,
      color: const Color(0xFF10B981),
      trailing: TextButton(
        onPressed: () => context.push('/${_institutionId!}/announcements'),
        child: const Text('View All'),
      ),
      child: _announcements.isEmpty
          ? const Center(child: Text('No recent announcements'))
          : Column(
              children: _announcements.map((ann) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_active_outlined, color: Colors.blue, size: 20),
                ),
                title: Text(ann.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(ann.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: () => context.push('/${_institutionId!}/announcements/${ann.id}', extra: ann),
              )).toList(),
            ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'label': 'Mark Attendance', 'icon': Icons.assignment_turned_in_rounded, 'color': const Color(0xFF4F46E5), 'route': '/faculty/mark-attendance'},
      {'label': 'Marks Entry', 'icon': Icons.grade_rounded, 'color': const Color(0xFF10B981), 'route': '/faculty/marks-entry'},
      {'label': 'Approve Leave', 'icon': Icons.check_circle_rounded, 'color': const Color(0xFF8B5CF6), 'route': '/faculty/leave-approval'},
      {'label': 'My Timetable', 'icon': Icons.calendar_month_rounded, 'color': const Color(0xFFF59E0B), 'route': '/faculty/timetable'},
    ];

    return _buildCard(
      title: 'Quick Actions',
      icon: Icons.bolt_rounded,
      color: const Color(0xFFF59E0B),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return InkWell(
            onTap: () => context.push('/${_institutionId!}${action['route']}'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(action['icon'] as IconData, color: action['color'] as Color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      action['label'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      {'title': 'Marked Attendance', 'subtitle': 'CS301 - 2:00 PM', 'time': '2h ago', 'icon': Icons.check_circle_outline, 'color': Colors.green},
      {'title': 'Updated Marks', 'subtitle': 'Algorithms Quiz 1', 'time': '4h ago', 'icon': Icons.edit_note_rounded, 'color': Colors.blue},
      {'title': 'Meeting Reminder', 'subtitle': 'Faculty Meeting at 4:30', 'time': 'Today', 'icon': Icons.alarm_rounded, 'color': Colors.orange},
    ];

    return _buildCard(
      title: 'Recent Activity',
      icon: Icons.history_rounded,
      color: const Color(0xFF8B5CF6),
      child: Column(
        children: activities.map((act) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Icon(act['icon'] as IconData, color: act['color'] as Color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(act['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(act['subtitle'] as String, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
              ),
              Text(act['time'] as String, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
