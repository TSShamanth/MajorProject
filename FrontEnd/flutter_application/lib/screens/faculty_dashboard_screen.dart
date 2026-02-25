import 'package:flutter/material.dart';
//import '../services/auth_service.dart';
import 'package:flutter_application/models/course_model.dart';
import 'package:flutter_application/models/time_slot_model.dart';
import 'package:flutter_application/models/timetable_entry_model.dart';
import 'package:flutter_application/models/room_model.dart';
import 'package:flutter_application/services/timetable_service.dart';
import 'package:flutter_application/services/attendance_service.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';

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
  int _notificationCount = 0;

  List<TimetableEntry> _todaySchedule = [];
  List<TimeSlot> _allTimeSlots = [];
  List<Course> _allCourses = [];
  List<Room> _allRooms = [];
  bool _isLoadingSchedule = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _institutionId = GoRouter.of(context)
          .routerDelegate
          .currentConfiguration
          .pathParameters['institutionId'];
      _fetchCurrentUser().then((_) => _fetchTodaySchedule());
    });
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
        AttendanceService.getSubjects(),
        _apiService.getRooms(_institutionId!),
      ]);

      final slots = results[0] as List<TimeSlot>;
      final allEntries = results[1] as List<TimetableEntry>;
      final courses = results[2] as List<Course>;
      final rooms = results[3] as List<Room>;

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
          _allCourses = courses;
          _allRooms = rooms;
          _isLoadingSchedule = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching faculty today schedule: $e');
      if (mounted) setState(() => _isLoadingSchedule = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      _fetchNotificationCount();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch user data: $e')),
      );
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _handleClockIn() async {
    if (_institutionId == null) return;
    setState(() => _isClockingIn = true);
    try {
      final position = await _determinePosition();
      final updatedUser = await _apiService.clockIn(
          _institutionId!, position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _currentUser = updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Successfully clocked in!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to clock in: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isClockingIn = false);
    }
  }

  Future<void> _handleClockOut() async {
    if (_institutionId == null) return;
    setState(() => _isClockingIn = true);
    try {
      final position = await _determinePosition();
      final updatedUser = await _apiService.clockOut(
          _institutionId!, position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _currentUser = updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Successfully clocked out!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to clock out: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
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
    ];
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final list = await _apiService.getNotifications();
      if (!mounted) return;
      setState(() {
        _notificationCount = list.where((n) => !n.read).length;
      });
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
        final isDesktop = constraints.maxWidth >= 1024;

        return Scaffold(
          backgroundColor: _bgColor,
          drawer: isMobile ? _buildMobileDrawer() : null,
          body: isMobile
              ? _buildMobileLayout(isMobile, isTablet, isDesktop)
              : Row(
                  children: [
                    _buildModernSidebar(),
                    Expanded(
                      child: Column(
                        children: [
                          _buildModernTopBar(isMobile: false),
                          _buildBreadcrumb(),
                          Expanded(
                            child: _isLoadingUser
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF4F46E5),
                                    ),
                                  )
                                : _buildDashboardContent(
                                    isMobile: isMobile,
                                    isTablet: isTablet,
                                    isDesktop: isDesktop,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // ── Mobile layout ──────────────────────────────────────────────────────────
  Widget _buildMobileLayout(bool isMobile, bool isTablet, bool isDesktop) {
    return Column(
      children: [
        _buildMobileTopBar(),
        Expanded(
          child: _isLoadingUser
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                )
              : _buildDashboardContent(
                  isMobile: isMobile,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                ),
        ),
      ],
    );
  }

  // ── Mobile Drawer ─────────────────────────────────────────────────────────
  Widget _buildMobileDrawer() {
    final menuItems = _menuItems();
    return Drawer(
      backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDarkMode
                    ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                    : [const Color(0xFF4F46E5), const Color(0xFF4338CA)],
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
                    'AcadWorkHub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: menuItems.map((item) {
                final isActive = item['active'] == true;
                return ListTile(
                  leading: Icon(
                    item['icon'] as IconData,
                    color: isActive ? const Color(0xFF4F46E5) : _textSecondary,
                  ),
                  title: Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: isActive ? const Color(0xFF4F46E5) : _textPrimary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
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

  // ── Mobile Top Bar ────────────────────────────────────────────────────────
  Widget _buildMobileTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu_rounded, color: _textPrimary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'AcadWorkHub',
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
          IconButton(
            icon: Icon(Icons.notifications_rounded, color: _textPrimary),
            onPressed: () {},
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
                        width: 1,
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
                          'AcadWorkHub',
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
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
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
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                    children: menuItems.map((item) {
                      final isActive = item['active'] == true;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final route = item['route'];
                              if (route != null && _institutionId != null) {
                                context.push('/$_institutionId${route as String}');
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white.withOpacity(_isDarkMode ? 0.1 : 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: isActive
                                    ? Border.all(
                                        color: Colors.white.withOpacity(_isDarkMode ? 0.2 : 0.3),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item['icon'] as IconData,
                                    color: Colors.white.withOpacity(isActive ? 1.0 : 0.7),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      item['label'] as String,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(isActive ? 1.0 : 0.8),
                                        fontSize: 15,
                                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (item['badge'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(10),
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
                        color: Colors.white.withOpacity(_isDarkMode ? 0.05 : 0.1),
                        width: 1,
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
                                  size: 16, color: Colors.white.withOpacity(0.6)),
                              const SizedBox(width: 8),
                              Text(
                                'Help & Support',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
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
                                  size: 16, color: Colors.white.withOpacity(0.6)),
                              const SizedBox(width: 8),
                              Text(
                                'Documentation',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
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

  // ── Modern Top Bar ────────────────────────────────────────────────────────
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
          if (!_sidebarExpanded)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF1F2937) : const Color(0xFF4F46E5),
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
                    child: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 18),
                  Icon(Icons.search_rounded, color: _textSecondary, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search students, courses...',
                        hintStyle: TextStyle(color: _textSecondary, fontSize: 15),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: TextStyle(color: _textPrimary, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Mark Attendance',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: IconButton(
              icon: Icon(
                _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: _isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFF4F46E5),
                size: 22,
              ),
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
              tooltip: _isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
          ),
          const SizedBox(width: 16),
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
                  icon: Icon(Icons.notifications_rounded, color: _textPrimary, size: 24),
                  onPressed: () {},
                ),
              ),
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
          Container(
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: _borderColor)),
            ),
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
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Faculty', style: TextStyle(fontSize: 13, color: _textSecondary)),
                  ],
                ),
                const SizedBox(width: 10),
                PopupMenuButton(
                  icon: Icon(Icons.arrow_drop_down_rounded, color: _textSecondary, size: 26),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: _cardColor,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: () {
                        if (_institutionId != null) {
                          context.push('/$_institutionId/faculty/profile');
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 20, color: _textPrimary),
                          const SizedBox(width: 14),
                          Text('Profile', style: TextStyle(fontSize: 15, color: _textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () {},
                      child: Row(
                        children: [
                          Icon(Icons.settings_rounded, size: 20, color: _textPrimary),
                          const SizedBox(width: 14),
                          Text('Settings', style: TextStyle(fontSize: 15, color: _textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () async {
                        final router = GoRouter.of(context);
                        await SessionManager.clearSession();
                        await AuthService.logout();
                        router.go('/login');
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 20, color: Color(0xFFEF4444)),
                          SizedBox(width: 14),
                          Text('Logout',
                              style: TextStyle(color: Color(0xFFEF4444), fontSize: 15)),
                        ],
                      ),
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

  // ── Breadcrumb ─────────────────────────────────────────────────────────────
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
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF4F46E5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dashboard content ──────────────────────────────────────────────────────
  Widget _buildDashboardContent({
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final padding = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);

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
              style: TextStyle(fontSize: isMobile ? 13 : 14, color: _textSecondary),
            ),
            SizedBox(height: isMobile ? 16 : 24),
            _buildClockInCard(),
            SizedBox(height: isMobile ? 16 : 20),
            _buildResponsiveStatsRow(isMobile, isTablet),
            SizedBox(height: isMobile ? 16 : 20),
            _buildResponsiveMainContent(isMobile, isTablet, isDesktop),
          ],
        ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Help & Support',
                          style: TextStyle(
                            color: Color(0xFFA5B4FC),
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Documentation',
                          style: TextStyle(
                            color: Color(0xFFA5B4FC),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Main Content Area - SCROLLABLE
          Expanded(
            child: Column(
              children: [
                // Top Bar - Fixed Height
                Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Search Bar
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          height: 40,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search students, courses...',
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 18),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Quick Action Button
                      ElevatedButton(
                        onPressed: () {
                          final institutionId = GoRouter.of(context)
                              .routerDelegate
                              .currentConfiguration
                              .pathParameters['institutionId'];
                          if (institutionId != null) {
                            context.push('/$institutionId/faculty/mark-attendance');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Mark Attendance', style: TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 12),
                      // Notifications
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF6B7280), size: 22),
                            onPressed: () {
                              if (_institutionId != null) {
                                context.push('/$_institutionId/notifications');
                                setState(() {
                                  _notificationCount = 0;
                                });
                              }
                            },
                          ),
                          if (_notificationCount > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$_notificationCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // User Profile
                      Container(
                        padding: const EdgeInsets.only(left: 12),
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Color(0xFFD1D5DB), width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4F46E5),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _currentUser != null && _currentUser!.displayName.isNotEmpty ? _currentUser!.displayName.substring(0, 2).toUpperCase() : '..',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentUser?.displayName ?? 'Loading...',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                Text(
                                  'FAC2021', // This should probably come from the user model
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout, color: Color(0xFF6B7280), size: 18),
                              onPressed: () async {
                                final router = GoRouter.of(context);
                                await SessionManager.clearSession();
                                await AuthService.logout();
                                router.go('/login');
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Breadcrumb - Fixed Height
                Container(
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        'Home',
                        style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                      ),
                      const Icon(Icons.chevron_right, size: 14, color: Color(0xFF6B7280)),
                      const Text(
                        'Dashboard',
                        style: TextStyle(fontSize: 13, color: Color(0xFF4F46E5), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                // Dashboard Content - Scrollable
                Expanded(
                  child: _isLoadingUser
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Welcome Section
                              Text(
                                'Welcome, ${_currentUser?.displayName ?? '...'}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              Text(
                                '${_currentUser?.programme ?? '...'} Department | FAC2021',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                              ),
                              const SizedBox(height: 10),
                              // Clock In Card
                              _buildClockInCard(),
                              const SizedBox(height: 10),
                              // Stats Cards - Fixed Height
                              SizedBox(
                                height: 75,
                                child: Row(
                                  children: [
                                    Expanded(child: _buildStatCard('Courses', '4', Icons.book_outlined, Colors.blue, '142 Students')),
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildStatCard('Evaluations', '28', Icons.assignment_outlined, Colors.orange, '3 Pending')),
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildStatCard('Placements', '32/42', Icons.work_outline, Colors.green, '76% Placed')),
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildStatCard('Classes', '6', Icons.calendar_today_outlined, Colors.purple, 'This Week')),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Main Content Grid - Intrinsic Height
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Column 1 - 35%
                                    Expanded(
                                      flex: 35,
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            height: 400,
                                            child: _buildTodaysScheduleCard(),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            height: 400,
                                            child: _buildRecentActivity(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Column 2 - 32%
                                    Expanded(
                                      flex: 32,
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            height: 280,
                                            child: _buildMenteesOverviewCard(),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            height: 250,
                                            child: _buildEventsMeetingsCard(),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            height: 270,
                                            child: _buildPayrollSummaryCard(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Column 3 - 33%
                                    Expanded(
                                      flex: 33,
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            height: 240,
                                            child: _buildQuickActionsCard(),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            height: 560,
                                            child: _buildLeaveStatusCard(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Clock-in card ─────────────────────────────────────────────────────────
  Widget _buildClockInCard() {
    final isClockedIn = _currentUser?.attendanceStatus == 'Clocked-in';
    final statusText =
        isClockedIn ? 'You are currently Clocked-in' : 'You are Clocked-out';
    final buttonText = isClockedIn ? 'Clock Out' : 'Clock In';
    final statusColor =
        isClockedIn ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                  Text(
                    'Attendance Status',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _buildResponsiveStatsRow(bool isMobile, bool isTablet) {
    final cards = [
      _buildStatCard('Courses', '4', 'This Semester',
          Icons.book_outlined, const Color(0xFF4F46E5)),
      _buildStatCard('Evaluations', '28', '3 Pending',
          Icons.assignment_outlined, const Color(0xFF10B981)),
      _buildStatCard('Placements', '32/42', '76% Placed',
          Icons.work_outline, const Color(0xFF8B5CF6)),
      _buildStatCard('Classes', '6', 'This Week',
          Icons.calendar_today_outlined, const Color(0xFFF59E0B)),
    ];

    if (isMobile) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount =
              (constraints.maxWidth / 180).floor().clamp(1, 2);
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: cards,
          );
        },
      );
    } else if (isTablet) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: cards,
      );
    } else {
      return Row(
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 16),
          Expanded(child: cards[1]),
          const SizedBox(width: 16),
          Expanded(child: cards[2]),
          const SizedBox(width: 16),
          Expanded(child: cards[3]),
        ],
      );
    }
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
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isSmall ? 24 : 30,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmall ? 11 : 13,
                color: _textSecondary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              subtext,
              style: TextStyle(
                fontSize: isSmall ? 10 : 12,
                color: _textSecondary.withOpacity(0.7),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      );
    });
  }

  // ── Responsive main content ────────────────────────────────────────────────
  Widget _buildResponsiveMainContent(bool isMobile, bool isTablet, bool isDesktop) {
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
          flex: 35,
          child: Column(
            children: [
              _buildTodaysScheduleCard(),
              const SizedBox(height: 16),
              _buildRecentActivityCard(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 32,
          child: Column(
            children: [
              _buildMenteesOverviewCard(),
              const SizedBox(height: 16),
              _buildEventsMeetingsCard(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 33,
          child: Column(
            children: [
              _buildQuickActionsCard(),
              const SizedBox(height: 16),
              _buildLeaveStatusCard(),
              const SizedBox(height: 16),
              _buildPayrollSummaryCard(),
            ],
          ),
        ),
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

  Widget _cardHeader(String title, IconData icon, Color color, {Widget? trailing}) {
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
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  // ── Today's Schedule ───────────────────────────────────────────────────────
  Widget _buildTodaysScheduleCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader("Today's Schedule",
              Icons.calendar_today_outlined, const Color(0xFF4F46E5)),
          const SizedBox(height: 16),
          if (_isLoadingSchedule)
            const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          else if (_todaySchedule.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No classes scheduled for today.',
                  style: TextStyle(fontSize: 13, color: _textSecondary),
                ),
              ),
            )
          else
            ..._todaySchedule.map((entry) {
              final slot = _allTimeSlots.firstWhere(
                (s) => s.id == entry.timeSlotId,
                orElse: () => TimeSlot(id: '', startTime: '--', endTime: '--', slotNumber: 0, institutionId: ''),
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
                orElse: () => Room(id: '', name: entry.roomId, capacity: 0, institutionId: ''),
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
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
                            Text(
                              course.courseName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Room: ${room.name}',
                              style: TextStyle(fontSize: 12, color: _textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.3)),
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
          _cardHeader('Recent Activity', Icons.timeline_rounded, const Color(0xFF8B5CF6),
              trailing: IconButton(
                icon: Icon(Icons.filter_list_rounded, size: 18, color: _textSecondary),
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
                  color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: activity['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activity['time'] as String,
                            style: TextStyle(fontSize: 11, color: _textSecondary),
                          ),
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
          _cardHeader('Mentees Overview', Icons.group_outlined, const Color(0xFF10B981)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(_isDarkMode ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(_isDarkMode ? 0.3 : 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(_isDarkMode ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.groups_rounded, color: Color(0xFF10B981), size: 20),
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
                            color: Color(0xFF10B981),
                          )),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF10B981), size: 22),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        border: Border.all(color: color.withOpacity(_isDarkMode ? 0.25 : 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: _textPrimary)),
          Text(count,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
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
          _cardHeader('Events & Meetings', Icons.celebration_outlined, const Color(0xFF8B5CF6),
              trailing: ElevatedButton.icon(
                onPressed: () {
                  if (_institutionId != null) {
                    context.push('/$_institutionId/events');
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Create',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildEventTile(String title, String badge, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(_isDarkMode ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(_isDarkMode ? 0.3 : 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13, color: color)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: _textSecondary)),
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
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Payroll Summary ────────────────────────────────────────────────────────
  Widget _buildPayrollSummaryCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Payroll Summary', Icons.attach_money, const Color(0xFF10B981)),
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
                    color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Basic',
                          style: TextStyle(color: _textSecondary, fontSize: 11)),
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
                    color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Allowances',
                          style: TextStyle(color: _textSecondary, fontSize: 11)),
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
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      {
        'label': 'Mark Attendance',
        'color': const Color(0xFF4F46E5),
        'icon': Icons.assignment_turned_in_rounded,
        'route': '/faculty/mark-attendance'
      },
      {
        'label': 'View History',
        'color': const Color(0xFF10B981),
        'icon': Icons.history_rounded,
        'route': '/faculty/attendance-history'
      },
      {
        'label': 'Apply Leave',
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.event_busy_rounded,
        'route': '/faculty/leave'
      },
      {
        'label': 'Approve Leaves',
        'color': const Color(0xFF64748B),
        'icon': Icons.check_circle_outline,
        'route': '/faculty/leave-approval'
      },
      {
        'label': 'Marks Entry',
        'color': const Color(0xFFF59E0B),
        'icon': Icons.grade_outlined,
        'route': '/faculty/marks-entry'
      },
      {
        'label': 'View Payroll',
        'color': const Color(0xFF0EA5E9),
        'icon': Icons.account_balance_wallet_rounded,
        'route': '/faculty/payroll'
      },
    ];

    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Quick Actions', Icons.bolt_rounded, const Color(0xFFF59E0B)),
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
                            color: action['color'] as Color,
                          ),
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
          _cardHeader('Leave Balance', Icons.description_outlined, const Color(0xFF4F46E5)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildLeaveBalanceTile('Casual', '12', const Color(0xFF4F46E5))),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildLeaveBalanceTile('Optional', '5', const Color(0xFF8B5CF6))),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildLeaveBalanceTile('Sick', '8', const Color(0xFF10B981))),
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
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        border: Border.all(color: color.withOpacity(_isDarkMode ? 0.3 : 0.2)),
      ),
      child: Column(
        children: [
          Text(count,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -1,
              )),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
} 

}