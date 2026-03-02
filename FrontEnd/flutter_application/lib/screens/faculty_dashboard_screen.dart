import 'package:flutter/material.dart';
import 'package:flutter_application/models/time_slot_model.dart';
import 'package:flutter_application/models/timetable_entry_model.dart';
import 'package:flutter_application/services/timetable_service.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/models/course_model.dart';
import 'package:flutter_application/models/room_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
// ─── Import the shared search bar ───────────────────────────────────────────
import 'global_search_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FACULTY SEARCH DATA SOURCE
// Covers every page, action, course, class, leave type, and student
// that a faculty member can access. Add new categories here as the app grows.
// ─────────────────────────────────────────────────────────────────────────────
class _FacultySearchDataSource implements SearchDataSource {
  final String institutionId;
  final List<Course> courses;
  final List<TimetableEntry> todaySchedule;
  final List<TimeSlot> timeSlots;
  final List<UserModel> mentees;

  _FacultySearchDataSource({
    required this.institutionId,
    required this.courses,
    required this.todaySchedule,
    required this.timeSlots,
    required this.mentees,
  });

  @override
  Future<List<SearchResult>> search(String query) async {
    final q = query.toLowerCase();
    final results = <SearchResult>[];

    // ── 1. PAGES  (sidebar navigation links) ─────────────────────────────────
    final pages = [
      {'label': 'Dashboard',          'sub': 'Home overview',                    'icon': Icons.dashboard_rounded,         'color': const Color(0xFF4F46E5), 'route': ''},
      {'label': 'Profile',            'sub': 'View & edit your profile',         'icon': Icons.person_outline,            'color': const Color(0xFF4F46E5), 'route': '/faculty/profile'},
      {'label': 'Virtual ID',         'sub': 'Your digital faculty ID card',     'icon': Icons.credit_card_outlined,      'color': const Color(0xFF4F46E5), 'route': '/faculty/virtual-id'},
      {'label': 'Timetable',          'sub': 'Weekly class schedule',            'icon': Icons.calendar_today_outlined,   'color': const Color(0xFF4F46E5), 'route': '/faculty/timetable'},
      {'label': 'Mentees',            'sub': 'Students under your mentorship',   'icon': Icons.group_outlined,            'color': const Color(0xFF10B981), 'route': '/faculty/mentees'},
      {'label': "Students' Fee Status",'sub': 'Check student fee records',       'icon': Icons.payments_outlined,         'color': const Color(0xFF10B981), 'route': '/faculty/student-fees'},
      {'label': 'Leave',              'sub': 'Apply for leave',                  'icon': Icons.description_outlined,      'color': const Color(0xFF8B5CF6), 'route': '/faculty/leave'},
      {'label': 'Approve Leaves',     'sub': 'Review student leave requests',    'icon': Icons.check_circle_outline,      'color': const Color(0xFF8B5CF6), 'route': '/faculty/leave-approval'},
      {'label': 'Marks Entry',        'sub': 'Enter & submit student marks',     'icon': Icons.grade_outlined,            'color': const Color(0xFFF59E0B), 'route': '/faculty/marks-entry'},
      {'label': 'Payroll',            'sub': 'Salary & payslip details',         'icon': Icons.attach_money,              'color': const Color(0xFF10B981), 'route': '/faculty/payroll'},
      {'label': 'Events',             'sub': 'Campus events & meetings',         'icon': Icons.celebration_outlined,      'color': const Color(0xFF8B5CF6), 'route': '/events'},
      {'label': 'Mark Attendance',    'sub': 'Record class attendance',          'icon': Icons.assignment_turned_in_rounded,'color': const Color(0xFF4F46E5), 'route': '/faculty/mark-attendance'},
      {'label': 'Clock-in History',   'sub': 'View your attendance log',         'icon': Icons.history_outlined,          'color': const Color(0xFF10B981), 'route': '/faculty/attendance-history'},
      {'label': 'Announcements',      'sub': 'Institution announcements',        'icon': Icons.announcement_outlined,     'color': const Color(0xFF4F46E5), 'route': '/announcements'},
    ];
    for (final p in pages) {
      final label = (p['label'] as String).toLowerCase();
      final sub   = (p['sub']   as String).toLowerCase();
      if (label.contains(q) || sub.contains(q)) {
        final route = p['route'] as String;
        results.add(SearchResult(
          id: 'page_$label',
          title: p['label'] as String,
          subtitle: p['sub'] as String,
          category: 'Pages',
          icon: p['icon'] as IconData,
          iconColor: p['color'] as Color,
          route: route.isEmpty ? '/$institutionId' : '/$institutionId$route',
        ));
      }
    }

    // ── 2. COURSES  (real data from API) ─────────────────────────────────────
    for (final c in courses) {
      if (c.courseName.toLowerCase().contains(q) ||
          c.courseCode.toLowerCase().contains(q) ||
          c.program.toLowerCase().contains(q)) {
        results.add(SearchResult(
          id: c.courseCode,
          title: c.courseName,
          subtitle: '${c.courseCode}  •  ${c.program}  •  Sem ${c.semester}',
          category: 'Courses',
          icon: Icons.book_outlined,
          iconColor: const Color(0xFF4F46E5),
          route: '/$institutionId/faculty/mark-attendance',
        ));
      }
    }

    // ── 3. TODAY'S CLASSES  (real timetable data) ─────────────────────────────
    for (final entry in todaySchedule) {
      final slot = timeSlots.where((s) => s.id == entry.timeSlotId).firstOrNull;
      final timeLabel = slot != null
          ? '${slot.startTime} – ${slot.endTime}'
          : 'Today';
      final courseName = courses
          .where((c) => c.courseCode == entry.courseCode)
          .firstOrNull
          ?.courseName ?? entry.courseCode;
      if (courseName.toLowerCase().contains(q) ||
          entry.courseCode.toLowerCase().contains(q) ||
          'today'.contains(q) ||
          'class'.contains(q) ||
          'schedule'.contains(q)) {
        results.add(SearchResult(
          id: 'today_${entry.courseCode}',
          title: courseName,
          subtitle: 'Today  •  $timeLabel  •  ${entry.program} Sem ${entry.semester}',
          category: "Today's Classes",
          icon: Icons.access_time_rounded,
          iconColor: const Color(0xFF10B981),
          route: '/$institutionId/faculty/mark-attendance',
        ));
      }
    }

    // ── 4. QUICK ACTIONS ─────────────────────────────────────────────────────
    final actions = [
      {'label': 'Mark Attendance',   'sub': 'Record attendance for a class',    'icon': Icons.assignment_turned_in_rounded, 'color': const Color(0xFF4F46E5), 'route': '/faculty/mark-attendance'},
      {'label': 'View Clock-in History','sub': 'Check your clock-in/out log',   'icon': Icons.history_rounded,              'color': const Color(0xFF10B981), 'route': '/faculty/attendance-history'},
      {'label': 'Apply Leave',       'sub': 'Submit a leave application',        'icon': Icons.event_busy_rounded,           'color': const Color(0xFF8B5CF6), 'route': '/faculty/leave'},
      {'label': 'Approve Leaves',    'sub': 'Approve or reject leave requests',  'icon': Icons.check_circle_outline,         'color': const Color(0xFF64748B), 'route': '/faculty/leave-approval'},
      {'label': 'Marks Entry',       'sub': 'Enter marks for your courses',      'icon': Icons.grade_outlined,               'color': const Color(0xFFF59E0B), 'route': '/faculty/marks-entry'},
      {'label': 'View Payroll',      'sub': 'See salary and payslip',            'icon': Icons.account_balance_wallet_rounded,'color': const Color(0xFF0EA5E9), 'route': '/faculty/payroll'},
      {'label': 'View Salary Slip',  'sub': 'Download monthly salary slip',      'icon': Icons.receipt_long_rounded,          'color': const Color(0xFF10B981), 'route': '/faculty/payroll'},
    ];
    for (final a in actions) {
      final label = (a['label'] as String).toLowerCase();
      final sub   = (a['sub']   as String).toLowerCase();
      if (label.contains(q) || sub.contains(q)) {
        results.add(SearchResult(
          id: 'action_$label',
          title: a['label'] as String,
          subtitle: a['sub'] as String,
          category: 'Quick Actions',
          icon: a['icon'] as IconData,
          iconColor: a['color'] as Color,
          route: '/$institutionId${a['route']}',
        ));
      }
    }

    // ── 5. LEAVE  ────────────────────────────────────────────────────────────
    final leaveTypes = [
      {'label': 'Casual Leave',   'sub': '12 days balance  •  Apply now', 'route': '/faculty/leave'},
      {'label': 'Sick Leave',     'sub': '8 days balance  •  Apply now',  'route': '/faculty/leave'},
      {'label': 'Optional Leave', 'sub': '5 days balance  •  Apply now',  'route': '/faculty/leave'},
    ];
    for (final l in leaveTypes) {
      if ((l['label']!).toLowerCase().contains(q) ||
          'leave'.contains(q)) {
        results.add(SearchResult(
          id: 'leave_${l['label']}',
          title: l['label']!,
          subtitle: l['sub']!,
          category: 'Leave',
          icon: Icons.description_outlined,
          iconColor: const Color(0xFF8B5CF6),
          route: '/$institutionId${l['route']}',
        ));
      }
    }

    // ── 6. PAYROLL  ──────────────────────────────────────────────────────────
    if ('payroll salary slip payment'.contains(q) && q.length >= 3) {
      results.add(SearchResult(
        id: 'payroll_summary',
        title: 'Payroll Summary',
        subtitle: 'Current month: ₹85,000  •  View full details',
        category: 'Payroll',
        icon: Icons.attach_money,
        iconColor: const Color(0xFF10B981),
        route: '/$institutionId/faculty/payroll',
      ));
    }

    // ── 7. STUDENTS / MENTEES  (real data when available) ────────────────────
    for (final m in mentees) {
      if (m.displayName.toLowerCase().contains(q) ||
          (m.email?.toLowerCase() ?? '').contains(q)) {
        results.add(SearchResult(
          id: m.uid,
          title: m.displayName,
          subtitle: m.email ?? 'Student',
          category: 'Students',
          icon: Icons.person_outline,
          iconColor: const Color(0xFF10B981),
          route: '/$institutionId/faculty/mentees',
        ));
      }
    }

    return results;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _sidebarExpanded = true;
  bool _isDarkMode = false;
  UserModel? _currentUser;
  bool _isLoadingUser = true;
  bool _isClockingIn = false;
  final ApiService _apiService = ApiService();
  String? _institutionId;

  List<TimetableEntry> _todaySchedule = [];
  List<TimeSlot> _allTimeSlots = [];
  List<Course> _allCourses = [];
  List<Room> _allRooms = [];
  List<UserModel> _mentees = [];
  int _notificationCount = 0;
  bool _isLoadingSchedule = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _institutionId = GoRouter.of(context)
          .routerDelegate
          .currentConfiguration
          .pathParameters['institutionId'];
      _fetchCurrentUser().then((_) {
        _fetchTodaySchedule();
        _fetchDashboardData();
        _fetchNotificationCount();
      });
    });
  }

  Future<void> _fetchDashboardData() async {
    if (_institutionId == null || _currentUser == null) return;

    try {
      final results = await Future.wait([
        _apiService.getRooms(_institutionId!),
        _apiService.getUsers(_institutionId!), // For mentees
        if (_currentUser!.departmentId != null)
          _apiService.getCourses(_institutionId!, _currentUser!.departmentId!)
        else
          Future.value(<Course>[]),
      ]);

      if (mounted) {
        setState(() {
          _allRooms = results[0] as List<Room>;
          final allUsers = results[1] as List<UserModel>;
          // Simple filter for mentees: students whose mentorName matches current user
          _mentees = allUsers
              .where((u) =>
                  u.role == 'student' &&
                  u.mentorName == _currentUser!.displayName)
              .toList();
          _allCourses = results[2] as List<Course>;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
    }
  }

  Future<void> _fetchTodaySchedule() async {
    if (_institutionId == null || _currentUser == null) return;

    try {
      final timetableService = TimetableService();
      final now = DateTime.now();
      final days = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday'
      ];
      final todayName = days[now.weekday - 1];

      final results = await Future.wait([
        timetableService.getTimeSlots(_institutionId!),
        timetableService.getTimetableForFaculty(_institutionId!, _currentUser!.uid),
      ]);

      final slots = results[0] as List<TimeSlot>;
      final allEntries = results[1] as List<TimetableEntry>;

      final todayEntries = allEntries.where((e) => e.day == todayName).toList();
      todayEntries.sort((a, b) {
        final slotA = slots.firstWhere((s) => s.id == a.timeSlotId);
        final slotB = slots.firstWhere((s) => s.id == b.timeSlotId);
        return slotA.slotNumber.compareTo(slotB.slotNumber);
      });

      if (mounted) {
        setState(() {
          _allTimeSlots = slots;
          _todaySchedule = todayEntries;
          _isLoadingSchedule = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching faculty today schedule: $e');
      if (mounted) setState(() => _isLoadingSchedule = false);
    }
  }

  Future<void> _fetchCurrentUser() async {
    if (_institutionId == null) return;
    try {
      final user = await _apiService.getMe(_institutionId!);
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _isLoadingUser = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch user data: $e')),
      );
      setState(() => _isLoadingUser = false);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _handleClockIn() async {
    if (_institutionId == null) return;
    setState(() => _isClockingIn = true);
    try {
      final pos = await _determinePosition();
      final updated = await _apiService.clockIn(_institutionId!, pos.latitude, pos.longitude);
      if (mounted) setState(() => _currentUser = updated);
    } catch (e) { /* error handling */ } finally {
      if (mounted) setState(() => _isClockingIn = false);
    }
  }

  Future<void> _handleClockOut() async {
    if (_institutionId == null) return;
    setState(() => _isClockingIn = true);
    try {
      final pos = await _determinePosition();
      final updated = await _apiService.clockOut(_institutionId!, pos.latitude, pos.longitude);
      if (mounted) setState(() => _currentUser = updated);
    } catch (e) { /* error handling */ } finally {
      if (mounted) setState(() => _isClockingIn = false);
    }
  }

  // ── Color helpers ──────────────────────────────────────────────────────────
  Color get _bgColor =>
      _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
  Color get _cardColor =>
      _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
  Color get _textPrimary =>
      _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
  Color get _textSecondary =>
      _isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get _borderColor =>
      _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

  // ── Sidebar menu items ────────────────────────────────────────────────────
  List<Map<String, Object?>> _menuItems() {
    return [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'active': true, 'route': null},
      {'icon': Icons.person_outline, 'label': 'Profile', 'active': false, 'route': '/faculty/profile'},
      {'icon': Icons.credit_card_outlined, 'label': 'Virtual ID', 'active': false, 'route': '/faculty/virtual-id'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Timetable', 'active': false, 'route': '/faculty/timetable'},
      {'icon': Icons.group_outlined, 'label': 'Mentees', 'active': false, 'badge': '8', 'route': '/faculty/mentees'},
      {'icon': Icons.payments_outlined, 'label': "Students' Fee Status", 'active': false, 'route': '/faculty/student-fees'},
      {'icon': Icons.description_outlined, 'label': 'Leave', 'active': false, 'route': '/faculty/leave'},
      {'icon': Icons.check_circle_outline, 'label': 'Approve Leaves', 'active': false, 'route': '/faculty/leave-approval'},
      {'icon': Icons.grade_outlined, 'label': 'Marks Entry', 'active': false, 'route': '/faculty/marks-entry'},
      {'icon': Icons.attach_money, 'label': 'Payroll', 'active': false, 'route': '/faculty/payroll'},
      {'icon': Icons.celebration_outlined, 'label': 'Events', 'active': false, 'route': '/events'},
      {'icon': Icons.assignment_outlined, 'label': 'Mark Attendance', 'active': false, 'route': '/faculty/mark-attendance'},
      {'icon': Icons.history_outlined, 'label': 'Clock-in History', 'active': false, 'route': '/faculty/attendance-history'},
      {'icon': Icons.announcement_outlined, 'label': 'Announcements', 'active': false, 'route': '/announcements'},
      {'icon': Icons.description_outlined, 'label': 'Surveys & Forms', 'active': false, 'route': '/faculty/forms'},
    ];
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final list = await _apiService.getNotifications();
      if (!mounted) return;
      setState(() {
        _notificationCount = list.where((n) => !n.read).length;
      });
    } catch (_) {}
  }

  // ── Build the search data source from all currently loaded data ──────────
  _FacultySearchDataSource get _searchDataSource => _FacultySearchDataSource(
        institutionId: _institutionId ?? '',
        courses: _allCourses,
        todaySchedule: _todaySchedule,
        timeSlots: _allTimeSlots,
        mentees: _mentees,
      );

  // ── Navigate to a search result — route is already fully formed ───────────
  void _onSearchResultTap(String route) {
    if (route.isNotEmpty) context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 768;
      final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
      final isDesktop = constraints.maxWidth >= 1024;

      return Scaffold(
        backgroundColor: _bgColor,
        drawer: isMobile ? _buildMobileDrawer() : null,
        body: Row(
          children: [
            if (!isMobile) _buildModernSidebar(),
            Expanded(
              child: Column(
                children: [
                  isMobile ? _buildMobileTopBar() : _buildModernTopBar(),
                  _buildBreadcrumb(),
                  Expanded(
                    child: _isLoadingUser
                        ? const Center(child: CircularProgressIndicator())
                        : _buildDashboardContent(isMobile, isTablet, isDesktop),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  void _handleLogout() async {
    final router = GoRouter.of(context);
    await SessionManager.clearSession();
    await AuthService.logout();
    router.go('/login');
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: _cardColor,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF4338CA)]),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                    child: Text('A',
                        style: TextStyle(
                            color: Color(0xFF4F46E5),
                            fontWeight: FontWeight.w900,
                            fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                const Text('Acadexa',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _menuItems().map((item) {
                final isActive = item['active'] == true;
                return ListTile(
                  leading: Icon(item['icon'] as IconData,
                      color:
                          isActive ? const Color(0xFF4F46E5) : _textSecondary),
                  title: Text(item['label'] as String,
                      style: TextStyle(
                          color: isActive
                              ? const Color(0xFF4F46E5)
                              : _textPrimary,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500)),
                  selected: isActive,
                  selectedTileColor: const Color(0xFF4F46E5).withOpacity(0.1),
                  onTap: () {
                    Navigator.pop(context);
                    final route = item['route'];
                    if (route != null && _institutionId != null) {
                      context.push('/$_institutionId${route as String}');
                    }
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1 — hamburger + logo + icons
          Row(
            children: [
              Builder(
                builder: (ctx) => IconButton(
                  icon: Icon(Icons.menu_rounded, color: _textPrimary),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Acadexa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: _isDarkMode
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF4F46E5),
                ),
                onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
              ),
              Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_rounded, color: _textPrimary),
                    onPressed: () {
                      if (_institutionId != null) {
                        context.push('/$_institutionId/notifications');
                        setState(() => _notificationCount = 0);
                      }
                    },
                  ),
                  if (_notificationCount > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Row 2 — active search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
            child: GlobalSearchBar(
              isDarkMode: _isDarkMode,
              height: 42,
              hintText: 'Search courses, students...',
              dataSource: _searchDataSource,
              onNavigate: _onSearchResultTap,
            ),
          ),
        ],
      ),
    );
  }

  // ── Modern Sidebar ────────────────────────────────────────────────────────
  Widget _buildModernSidebar() {
    final menuItems = _menuItems();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _sidebarExpanded ? 270 : 0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode
              ? [const Color(0xFF1F2937), const Color(0xFF111827)]
              : [const Color(0xFF4F46E5), const Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: _sidebarExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.15),
                  blurRadius: 20,
                  offset: const Offset(4, 0),
                ),
              ]
            : [],
      ),
      child: _sidebarExpanded
          ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(_isDarkMode ? 0.05 : 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'A',
                            style: TextStyle(
                              color: _isDarkMode
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFF4F46E5),
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Acadexa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(_isDarkMode ? 0.05 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left_rounded,
                              color: Colors.white, size: 24),
                          onPressed: () => setState(() => _sidebarExpanded = false),
                          tooltip: 'Collapse sidebar',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: menuItems.map((item) {
                      final isActive = item['active'] == true;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final route = item['route'];
                              if (route != null && _institutionId != null) {
                                context.push(
                                    '/$_institutionId${route as String}');
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white
                                        .withOpacity(_isDarkMode ? 0.1 : 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: isActive
                                    ? Border.all(
                                        color: Colors.white.withOpacity(
                                            _isDarkMode ? 0.2 : 0.3),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item['icon'] as IconData,
                                    color: Colors.white
                                        .withOpacity(isActive ? 1.0 : 0.7),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      item['label'] as String,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(
                                            isActive ? 1.0 : 0.8),
                                        fontSize: 15,
                                        fontWeight: isActive
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (item['badge'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        item['badge'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color:
                            Colors.white.withOpacity(_isDarkMode ? 0.05 : 0.1),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.help_outline_rounded,
                                  size: 16,
                                  color: Colors.white.withOpacity(0.6)),
                              const SizedBox(width: 8),
                              Text('Help & Support',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.description_outlined,
                                  size: 16,
                                  color: Colors.white.withOpacity(0.6)),
                              const SizedBox(width: 8),
                              Text('Documentation',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  // ── Modern Top Bar (desktop / tablet) ─────────────────────────────────────
  Widget _buildModernTopBar({bool isMobile = false}) {
    if (isMobile) return const SizedBox.shrink();

    final displayName = _currentUser?.displayName ?? 'Faculty';
    final initials = displayName.length >= 2
        ? displayName.substring(0, 2).toUpperCase()
        : 'FC';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sidebar re-open button (shown when sidebar is collapsed)
          if (!_sidebarExpanded)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? const Color(0xFF1F2937)
                    : const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (_isDarkMode
                            ? const Color(0xFF1F2937)
                            : const Color(0xFF4F46E5))
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _sidebarExpanded = true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    child: const Icon(Icons.menu_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),

          // ── ACTIVE SEARCH BAR ─────────────────────────────────────────────
          Expanded(
            child: GlobalSearchBar(
              isDarkMode: _isDarkMode,
              height: 46,
              hintText: 'Search students, courses...',
              dataSource: _searchDataSource,
              onNavigate: _onSearchResultTap,
            ),
          ),
          // ─────────────────────────────────────────────────────────────────

          const SizedBox(width: 16),
          // Mark Attendance button
          ElevatedButton(
            onPressed: () {
              if (_institutionId != null) {
                context.push('/$_institutionId/faculty/mark-attendance');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Mark Attendance',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 16),
          // Dark mode toggle
          Container(
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: IconButton(
              icon: Icon(
                _isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: _isDarkMode
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFF4F46E5),
                size: 22,
              ),
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
              tooltip: _isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
          ),
          const SizedBox(width: 16),
          // Notifications
          Stack(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.notifications_rounded,
                      color: _textPrimary, size: 24),
                  onPressed: () {
                    if (_institutionId != null) {
                      context.push('/$_institutionId/notifications');
                      setState(() => _notificationCount = 0);
                    }
                  },
                ),
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          // User profile + dropdown
          Container(
            padding: const EdgeInsets.only(left: 20),
            decoration:
                BoxDecoration(border: Border(left: BorderSide(color: _borderColor))),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: Center(
                    child: Text(initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        )),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(displayName,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary)),
                    const SizedBox(height: 2),
                    Text('Faculty',
                        style: TextStyle(
                            fontSize: 13, color: _textSecondary)),
                  ],
                ),
                const SizedBox(width: 10),
                PopupMenuButton(
                  icon: Icon(Icons.arrow_drop_down_rounded,
                      color: _textSecondary, size: 26),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  color: _cardColor,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      onTap: () {
                        if (_institutionId != null) {
                          context.push('/$_institutionId/faculty/profile');
                        }
                      },
                      child: Row(children: [
                        Icon(Icons.person_outline,
                            size: 20, color: _textPrimary),
                        const SizedBox(width: 14),
                        Text('Profile',
                            style: TextStyle(
                                fontSize: 15, color: _textPrimary)),
                      ]),
                    ),
                    PopupMenuItem(
                      onTap: () {},
                      child: Row(children: [
                        Icon(Icons.settings_rounded,
                            size: 20, color: _textPrimary),
                        const SizedBox(width: 14),
                        Text('Settings',
                            style: TextStyle(
                                fontSize: 15, color: _textPrimary)),
                      ]),
                    ),
                    PopupMenuItem(
                      onTap: _handleLogout,
                      child: const Row(children: [
                        Icon(Icons.logout_rounded,
                            size: 20, color: Color(0xFFEF4444)),
                        SizedBox(width: 14),
                        Text('Logout',
                            style: TextStyle(
                                color: Color(0xFFEF4444), fontSize: 15)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          Text('Home', style: TextStyle(fontSize: 14, color: _textSecondary)),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right_rounded, size: 18, color: _textSecondary),
          const SizedBox(width: 10),
          const Text('Dashboard',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(bool isMobile, bool isTablet, bool isDesktop) {
    final padding = isMobile ? 16.0 : 28.0;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${_currentUser?.displayName ?? '...'}',
              style: TextStyle(
                fontSize: isMobile ? 22 : (isTablet ? 24 : 26),
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_currentUser?.programme ?? '...'} Department',
              style: TextStyle(
                  fontSize: isMobile ? 13 : 14, color: _textSecondary),
            ),
            SizedBox(height: isMobile ? 16 : 24),
            _buildClockInCard(),
            SizedBox(height: isMobile ? 16 : 20),
            _buildResponsiveStatsRow(isMobile),
            SizedBox(height: isMobile ? 16 : 20),
            _buildResponsiveMainContent(isMobile, isTablet, isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildClockInCard() {
    final isClockedIn = _currentUser?.attendanceStatus == 'Clocked-in';
    final statusColor = isClockedIn ? Colors.green : Colors.red;
    final statusText = isClockedIn ? 'Clocked-in' : 'Not Clocked-in';
    final buttonText = isClockedIn ? 'Clock Out' : 'Clock In';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: _borderColor)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isClockedIn ? Icons.login_rounded : Icons.logout_rounded,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Attendance Status',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(statusText,
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _isClockingIn
                ? null
                : (isClockedIn ? _handleClockOut : _handleClockIn),
            icon: _isClockingIn
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Icon(
                    isClockedIn ? Icons.logout_rounded : Icons.login_rounded,
                    size: 18),
            label: _isClockingIn
                ? const SizedBox.shrink()
                : Text(buttonText,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: statusColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveStatsRow(bool isMobile) {
    return LayoutBuilder(builder: (context, constraints) {
      final cards = [
        _buildStatCard('Courses', '4', '142 Students', Icons.book, Colors.blue),
        _buildStatCard('Evaluations', '28', '3 Pending', Icons.assignment, Colors.orange),
        _buildStatCard('Placements', '32/42', '76% Placed', Icons.work, Colors.green),
        _buildStatCard('Classes', '6', 'This Week', Icons.calendar_today, Colors.purple),
      ];
      if (isMobile) {
        return Column(children: [
          Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
        ]);
      }
      return Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: c))).toList());
    });
  }

  Widget _buildStatCard(String title, String value, String subtext,
      IconData icon, Color color) {
    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 180;
      return Container(
        padding: EdgeInsets.all(isSmall ? 14 : 20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isDarkMode ? 0.1 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isSmall ? 8 : 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: isSmall ? 20 : 22),
            ),
            SizedBox(height: isSmall ? 12 : 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                    fontSize: isSmall ? 24 : 30,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -1,
                  )),
            ),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(
                  fontSize: isSmall ? 11 : 13,
                  color: _textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
            const SizedBox(height: 2),
            Text(subtext,
                style: TextStyle(
                  fontSize: isSmall ? 10 : 12,
                  color: _textSecondary.withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
          ],
        ),
      );
    });
  }

  // ── Responsive main content ────────────────────────────────────────────────
  Widget _buildResponsiveMainContent(
      bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile || isTablet) {
      return Column(
        children: [
          _buildTodaysScheduleCard(),
          const SizedBox(height: 16),
          _buildMenteesOverviewCard(),
          const SizedBox(height: 16),
          _buildQuickActionsCard(),
          const SizedBox(height: 16),
          _buildLeaveStatusCard(),
          const SizedBox(height: 16),
          _buildPayrollSummaryCard(),
          const SizedBox(height: 16),
          _buildEventsMeetingsCard(),
          const SizedBox(height: 16),
          _buildRecentActivityCard(),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            flex: 3,
            child: Column(children: [
              _buildTodaysScheduleCard(),
              const SizedBox(height: 16),
              _buildRecentActivityCard()
            ])),
        const SizedBox(width: 16),
        Expanded(
            flex: 2,
            child: Column(children: [
              _buildQuickActionsCard(),
              const SizedBox(height: 16),
              _buildPayrollSummaryCard()
            ])),
      ],
    );
  }

  // ── Shared card container helper ──────────────────────────────────────────
  Widget _cardContainer({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.1 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardHeader(String title, IconData icon, Color color,
      {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(title,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
          ],
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  // ── Today's Schedule ───────────────────────────────────────────────────────
  Widget _buildTodaysScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Schedule",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_isLoadingSchedule)
            const Center(
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          else if (_todaySchedule.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No classes scheduled for today.',
                    style: TextStyle(fontSize: 13, color: _textSecondary)),
              ),
            )
          else
            ..._todaySchedule.map((entry) {
              final slot = _allTimeSlots.firstWhere(
                (s) => s.id == entry.timeSlotId,
                orElse: () => TimeSlot(
                    id: '',
                    startTime: '--',
                    endTime: '--',
                    slotNumber: 0,
                    institutionId: ''),
              );
              final course = _allCourses.firstWhere(
                (c) => c.courseCode == entry.courseCode,
                orElse: () => Course(
                    courseCode: '',
                    courseName: 'Unknown',
                    facultyUid: '',
                    institutionId: '',
                    program: '',
                    semester: '',
                    studentsEnrolled: [],
                    totalClasses: ''),
              );
              final room = _allRooms.firstWhere(
                (r) => r.id == entry.roomId,
                orElse: () => Room(
                    id: '',
                    name: entry.roomId,
                    capacity: 0,
                    institutionId: ''),
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? const Color(0xFF111827)
                        : _bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF4F46E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${slot.startTime} - ${slot.endTime}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(course.courseName,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _textPrimary)),
                            const SizedBox(height: 2),
                            Text('Room: ${room.name}',
                                style: TextStyle(
                                    fontSize: 12, color: _textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color:
                                  const Color(0xFF10B981).withOpacity(0.3)),
                        ),
                        child: Text(
                          '${entry.program} Sem ${entry.semester}',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Recent Activity ────────────────────────────────────────────────────────
  Widget _buildRecentActivityCard() {
    final activities = [
      {'title': 'Grade Assignment - CS301', 'time': 'Due Today', 'color': const Color(0xFFEF4444)},
      {'title': 'Student Profile Approval', 'time': '3 pending', 'color': const Color(0xFFF59E0B)},
      {'title': 'Lecture: Algorithms', 'time': 'Today 2:00 PM', 'color': const Color(0xFF4F46E5)},
      {'title': 'Mark Attendance - CSE-A', 'time': '09:00 AM', 'color': const Color(0xFF8B5CF6)},
      {'title': 'Faculty Meeting', 'time': 'Tomorrow', 'color': const Color(0xFF10B981)},
    ];

    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Recent Activity', Icons.timeline_rounded,
              const Color(0xFF8B5CF6),
              trailing: IconButton(
                icon: Icon(Icons.filter_list_rounded,
                    size: 18, color: _textSecondary),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )),
          const SizedBox(height: 16),
          ...activities.map((activity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? const Color(0xFF111827)
                      : _bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: activity['color'] as Color,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(activity['title'] as String,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary)),
                          const SizedBox(height: 2),
                          Text(activity['time'] as String,
                              style: TextStyle(
                                  fontSize: 11, color: _textSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: activity['color'] as Color),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Mentees Overview ───────────────────────────────────────────────────────
  Widget _buildMenteesOverviewCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Mentees Overview', Icons.group_outlined,
              const Color(0xFF10B981)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981)
                  .withOpacity(_isDarkMode ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF10B981)
                      .withOpacity(_isDarkMode ? 0.3 : 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981)
                        .withOpacity(_isDarkMode ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.groups_rounded,
                      color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Mentees',
                          style: TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      const Text('24',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF10B981), size: 22),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildMenteeTile('Excellent (90%+)', '12', const Color(0xFF10B981)),
          const SizedBox(height: 8),
          _buildMenteeTile('Good (75–90%)', '8', const Color(0xFF4F46E5)),
          const SizedBox(height: 8),
          _buildMenteeTile('Needs Attention', '4', const Color(0xFFF59E0B)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_institutionId != null) {
                  context.push('/$_institutionId/faculty/mentees');
                }
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('View All Mentees',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenteeTile(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(_isDarkMode ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: color.withOpacity(_isDarkMode ? 0.25 : 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary)),
          Text(count,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ],
      ),
    );
  }

  // ── Events & Meetings ──────────────────────────────────────────────────────
  Widget _buildEventsMeetingsCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Events & Meetings', Icons.celebration_outlined,
              const Color(0xFF8B5CF6),
              trailing: ElevatedButton.icon(
                onPressed: () {
                  if (_institutionId != null) {
                    context.push('/$_institutionId/events');
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Create',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              )),
          const SizedBox(height: 16),
          _buildEventTile('Faculty Meeting', 'Tomorrow',
              '10:00 AM | Conference Hall', const Color(0xFF8B5CF6)),
          const SizedBox(height: 10),
          _buildEventTile('Tech Workshop', 'Jan 10',
              'Organized by: You', const Color(0xFF4F46E5)),
        ],
      ),
    );
  }

  Widget _buildEventTile(
      String title, String badge, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(_isDarkMode ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: color.withOpacity(_isDarkMode ? 0.3 : 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style:
                        TextStyle(fontSize: 12, color: _textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(badge,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
              'Payroll Summary', Icons.attach_money, const Color(0xFF10B981)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Month',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                const Text('₹85,000',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? const Color(0xFF111827)
                        : _bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Basic',
                          style: TextStyle(
                              color: _textSecondary, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text('₹60,000',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _textPrimary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? const Color(0xFF111827)
                        : _bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Allowances',
                          style: TextStyle(
                              color: _textSecondary, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text('₹25,000',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _textPrimary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_institutionId != null) {
                  context.push('/$_institutionId/faculty/payroll');
                }
              },
              icon: const Icon(Icons.receipt_long_rounded, size: 16),
              label: const Text('View Salary Slip',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Actions ──────────────────────────────────────────────────────────
  Widget _buildQuickActionsCard() {
    final actions = [
      {'label': 'Mark Attendance', 'color': const Color(0xFF4F46E5), 'icon': Icons.assignment_turned_in_rounded, 'route': '/faculty/mark-attendance'},
      {'label': 'View History', 'color': const Color(0xFF10B981), 'icon': Icons.history_rounded, 'route': '/faculty/attendance-history'},
      {'label': 'Apply Leave', 'color': const Color(0xFF8B5CF6), 'icon': Icons.event_busy_rounded, 'route': '/faculty/leave'},
      {'label': 'Approve Leaves', 'color': const Color(0xFF64748B), 'icon': Icons.check_circle_outline, 'route': '/faculty/leave-approval'},
      {'label': 'Marks Entry', 'color': const Color(0xFFF59E0B), 'icon': Icons.grade_outlined, 'route': '/faculty/marks-entry'},
      {'label': 'View Payroll', 'color': const Color(0xFF0EA5E9), 'icon': Icons.account_balance_wallet_rounded, 'route': '/faculty/payroll'},
      {'label': 'Surveys & Forms', 'color': const Color(0xFF4F46E5), 'icon': Icons.description_outlined, 'route': '/faculty/forms'},
    ];

    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
              'Quick Actions', Icons.bolt_rounded, const Color(0xFFF59E0B)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return InkWell(
                onTap: () {
                  final route = action['route'] as String?;
                  if (route != null && _institutionId != null) {
                    context.push('/$_institutionId$route');
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (action['color'] as Color)
                        .withOpacity(_isDarkMode ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: (action['color'] as Color)
                            .withOpacity(_isDarkMode ? 0.3 : 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(action['icon'] as IconData,
                          color: action['color'] as Color, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          action['label'] as String,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: action['color'] as Color),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Leave Status ───────────────────────────────────────────────────────────
  Widget _buildLeaveStatusCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Leave Balance', Icons.description_outlined,
              const Color(0xFF4F46E5)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildLeaveBalanceTile(
                      'Casual', '12', const Color(0xFF4F46E5))),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildLeaveBalanceTile(
                      'Optional', '5', const Color(0xFF8B5CF6))),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildLeaveBalanceTile(
                      'Sick', '8', const Color(0xFF10B981))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_institutionId != null) {
                  context.push('/$_institutionId/faculty/leave');
                }
              },
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: const Text('Apply for Leave',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveBalanceTile(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(_isDarkMode ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: color.withOpacity(_isDarkMode ? 0.3 : 0.2)),
      ),
      child: Column(
        children: [
          Text(count,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -1)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}