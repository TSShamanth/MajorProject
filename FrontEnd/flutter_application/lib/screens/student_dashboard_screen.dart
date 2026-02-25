import 'package:flutter/material.dart';
import 'package:flutter_application/models/course_model.dart';
import 'package:flutter_application/models/time_slot_model.dart';
import 'package:flutter_application/models/timetable_entry_model.dart';
import 'package:flutter_application/models/room_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/attendance_service.dart';
import 'package:flutter_application/services/timetable_service.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import 'dart:math' as math;

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isDarkMode = false;
  bool _isSidebarCollapsed = false;
  // bool _isMobileSidebarOpen = false;
  final TextEditingController _searchController = TextEditingController();
  int _notificationCount = 0;

  List<TimetableEntry> _todaySchedule = [];
  List<TimeSlot> _allTimeSlots = [];
  List<Course> _allCourses = [];
  List<Room> _allRooms = [];
  UserModel? _user;
  Map<String, dynamic>? _academicSummary;
  bool _isLoadingSchedule = true;
  bool _isLoadingSummary = true;
  double _attendancePercentage = 0.0;

  Future<void> _fetchTodaySchedule() async {
    final institutionId = _getInstitutionId();
    if (institutionId.isEmpty) return;

    try {
      final timetableService = TimetableService();
      final apiService = ApiService();
      
      final user = await apiService.getMe(institutionId);
      if (mounted) {
        setState(() {
          _user = user;
          _attendancePercentage = user.attendancePercentage ?? 0.0;
        });
      }
      if (user.departmentId == null || user.programme == null || user.sem == null || user.sectionId == null) {
        if (mounted) {
          setState(() {
            _isLoadingSchedule = false;
            _isLoadingSummary = false;
          });
        }
        return;
      }

      _fetchAcademicSummary(institutionId, user.uid);

      final now = DateTime.now();
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final todayName = days[now.weekday - 1];
      debugPrint('Student Dashboard: Fetching schedule for $todayName');

      final results = await Future.wait([
        timetableService.getTimeSlots(institutionId),
        timetableService.getTimetableForClass(institutionId, user.departmentId!, user.programme!, user.sem!, user.sectionId!),
        apiService.getCourses(institutionId, user.departmentId!),
        apiService.getRooms(institutionId),
      ]);

      final slots = results[0] as List<TimeSlot>;
      final allEntries = results[1] as List<TimetableEntry>;
      final courses = results[2] as List<Course>;
      final rooms = results[3] as List<Room>;

      final todayEntries = allEntries.where((e) => e.day == todayName).toList();
      
      // Robust sorting
      todayEntries.sort((a, b) {
        final slotA = slots.indexWhere((s) => s.id == a.timeSlotId);
        final slotB = slots.indexWhere((s) => s.id == b.timeSlotId);
        return slotA.compareTo(slotB);
      });

      if (mounted) {
        setState(() {
          _allTimeSlots = slots;
          _todaySchedule = todayEntries;
          _allCourses = courses;
          _allRooms = rooms;
          _user = user;
          _isLoadingSchedule = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching today schedule: $e');
      if (mounted) {
        setState(() {
          _isLoadingSchedule = false;
          _isLoadingSummary = false;
        });
      }
    }
  }

  Future<void> _fetchAcademicSummary(String institutionId, String studentId) async {
    try {
      final apiService = ApiService();
      final results = await Future.wait([
        apiService.getAcademicSummary(institutionId, studentId),
        AttendanceService.getSubjectWiseAttendance(studentId),
      ]);

      if (mounted) {
        final attendanceData = results[1] as List<dynamic>;
        double totalPct = 0;
        if (attendanceData.isNotEmpty) {
          for (var item in attendanceData) {
            totalPct += (item.attendancePercentage as num).toDouble();
          }
          _attendancePercentage = totalPct / attendanceData.length;
        }

        setState(() {
          _academicSummary = results[0] as Map<String, dynamic>;
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching academic summary: $e');
      if (mounted) {
        setState(() => _isLoadingSummary = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTodaySchedule();
    });
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
    _cardAnimationController.forward();
    _fetchNotificationCount();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchProfile() async {
    if (_uid == null) throw Exception('Not logged in');
    return await _firestore.collection('users').doc(_uid).get();
  }

  String _getInstitutionId() {
    return GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'] ?? '';
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final notifications = await ApiService().getNotifications();
      if (!mounted) return;
      setState(() {
        _notificationCount = notifications.where((n) => !n.read).length;
      });
    } catch (e) {
      // ignore errors
    }
  }

  void _navigateToRoute(String label) {
    final institutionId = _getInstitutionId();
    final routes = {
      'Dashboard': '/$institutionId/student/dashboard',
      'Profile': '/$institutionId/student/profile',
      'My Profile': '/$institutionId/student/profile',
      'Virtual ID': '/$institutionId/student/virtual-id',
      'Timetable': '/$institutionId/student/timetable',
      'My Mentor': '/$institutionId/student/my-mentors',
      'My Hall Tickets': '/$institutionId/student/hall-tickets',
      'Academics': '/$institutionId/student/academics',
      'Academic Records': '/$institutionId/student/academics',
      'Attendance': '/$institutionId/student/attendance',
      'Leave': '/$institutionId/student/leave',
      'Events': '/$institutionId/events',
      'Events & Calendar': '/$institutionId/events',
      'Placements': '/$institutionId/student/placements',
      'Assignments': '/$institutionId/student/academics',
      'Assignments & Tasks': '/$institutionId/student/academics',
      'Credits': '/$institutionId/student/academics',
      'Announcements': '/$institutionId/announcements',
      'Notifications': '/$institutionId/notifications',
      'Messages': '/$institutionId/student/messages',
      'Fees': '/$institutionId/student/fees',
      'Study Planner': '/$institutionId/student/study-planner',
      'Notes': '/$institutionId/student/notes'
    };
    if (routes.containsKey(label)) {
      // when opening notifications, clear the badge immediately
      if (label == 'Notifications') {
        setState(() {
          _notificationCount = 0;
        });
      }
      context.push(routes[label]!);
    }
  }

  Color get _bgColor => _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA);
  Color get _cardColor => _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
  Color get _textPrimary => _isDarkMode ? Colors.white : const Color(0xFF1F2937);
  Color get _textSecondary => _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
  Color get _borderColor => _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
  Color get _sidebarColor => _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width < 1024;
    
    return Scaffold(
      backgroundColor: _bgColor,
      drawer: isMobile ? _buildMobileDrawer() : null,
      body: Row(
        children: [
          // Sidebar - Only show on desktop/tablet
          if (!isMobile) _buildSidebar(isTablet),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isMobile),
                _buildBreadcrumb(),
                Expanded(
                  child: _buildDashboardContent(isMobile, isTablet),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: _sidebarColor,
      child: _buildSidebarContent(false),
    );
  }

  Widget _buildSidebar(bool isTablet) {
    final width = _isSidebarCollapsed ? 70.0 : 260.0;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: width,
      color: _sidebarColor,
      child: _buildSidebarContent(isTablet),
    );
  }

  Widget _buildSidebarContent(bool isTablet) {
    final menuItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'active': true},
      {'icon': Icons.person_outline_rounded, 'label': 'My Profile'},
      {'icon': Icons.supervisor_account_rounded, 'label': 'My Mentor'},
      {'icon': Icons.credit_card_rounded, 'label': 'Virtual ID'},
      {'icon': Icons.schedule_rounded, 'label': 'Timetable'},
      {'icon': Icons.article_outlined, 'label': 'My Hall Tickets'},
      {'icon': Icons.menu_book_rounded, 'label': 'Academic Records'},
      {'icon': Icons.assignment_rounded, 'label': 'Assignments & Tasks', 'badge': '5'},
      {'icon': Icons.event_busy_rounded, 'label': 'Leave'},
      {'icon': Icons.calendar_today_rounded, 'label': 'Events & Calendar'},
      {'icon': Icons.business_center_rounded, 'label': 'Placements', 'badge': '12'},
      {'icon': Icons.campaign_rounded, 'label': 'Announcements'},
      {'icon': Icons.message_rounded, 'label': 'Messages'},
      {'icon': Icons.payment_rounded, 'label': 'Fees'},
      {'icon': Icons.edit_note_rounded, 'label': 'Study Planner'},
      {'icon': Icons.notes_rounded, 'label': 'Notes'}
    ];

    return Column(
      children: [
        // Logo Area
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: _isSidebarCollapsed
              ? Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                )
              : Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            color: Color(0xFF4F46E5),
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Acadexa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),

        // Menu Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: menuItems.map((item) {
              final isActive = item['active'] == true;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateToRoute(item['label'] as String),
                    borderRadius: BorderRadius.circular(8),
                    child: Tooltip(
                      message: _isSidebarCollapsed ? item['label'] as String : '',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isActive
                              ? Border(
                                  left: BorderSide(color: Colors.white, width: 3),
                                )
                              : null,
                        ),
                        child: _isSidebarCollapsed
                            ? Stack(
                                children: [
                                  Center(
                                    child: Icon(
                                      item['icon'] as IconData,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  if (item['badge'] != null)
                                    Positioned(
                                      right: 0,
                                      top: 0,
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
                              )
                            : Row(
                                children: [
                                  Icon(
                                    item['icon'] as IconData,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item['label'] as String,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (item['badge'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        item['badge'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Footer
        if (!_isSidebarCollapsed)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help & Support',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Documentation',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTopBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(
          bottom: BorderSide(color: _borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mobile Menu Button OR Desktop Collapse Button
          if (isMobile)
            IconButton(
              icon: Icon(Icons.menu_rounded, color: _textPrimary, size: 24),
              onPressed: () => Scaffold.of(context).openDrawer(),
              padding: EdgeInsets.zero,
            )
          else
            IconButton(
              icon: Icon(
                _isSidebarCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
                color: _textPrimary,
                size: 22,
              ),
              onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
              tooltip: _isSidebarCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
            ),
          
          if (isMobile) const SizedBox(width: 8),

          // Search Bar
          if (!isMobile)
            Expanded(
              flex: 2,
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search_rounded, color: _textSecondary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search assignments, courses, placements...',
                          hintStyle: TextStyle(
                            color: _textSecondary,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: TextStyle(color: _textPrimary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const Spacer(),

          // Virtual ID Button - Hide on small mobile
          if (!isMobile || MediaQuery.of(context).size.width > 400)
            InkWell(
              onTap: () => _navigateToRoute('Virtual ID'),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 38,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card_rounded, color: Colors.white, size: 15),
                      if (!isMobile) ...[
                        const SizedBox(width: 6),
                        const Text(
                          'Virtual ID',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(width: 10),

          // Notifications
          Stack(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.notifications_outlined, color: _textPrimary, size: 18),
                  onPressed: () => _navigateToRoute('Notifications'),
                  padding: EdgeInsets.zero,
                ),
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          if (!isMobile) ...[
            const SizedBox(width: 10),
            // Dark Mode Toggle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: _textPrimary,
                  size: 18,
                ),
                onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 14),
          ],

          // User Profile - Simplified on mobile
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: _fetchProfile(),
            builder: (context, snapshot) {
              String name = 'Student';
              
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data();
                name = data?['name'] ?? 'Student';
              }

              if (isMobile) {
                return PopupMenuButton(
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 18),
                          const SizedBox(width: 10),
                          const Text('Profile'),
                        ],
                      ),
                      onTap: () => _navigateToRoute('Profile'),
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          const Icon(Icons.settings_outlined, size: 18),
                          const SizedBox(width: 10),
                          const Text('Settings'),
                        ],
                      ),
                      onTap: () => _navigateToRoute('Settings'),
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(
                            _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(_isDarkMode ? 'Light Mode' : 'Dark Mode'),
                        ],
                      ),
                      onTap: () => setState(() => _isDarkMode = !_isDarkMode),
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                          SizedBox(width: 10),
                          Text('Logout', style: TextStyle(color: Color(0xFFEF4444))),
                        ],
                      ),
                      onTap: () async {
                        final router = GoRouter.of(context);
                        await SessionManager.clearSession();
                        await AuthService.logout();
                        router.go('/login');
                      },
                    ),
                  ],
                );
              }

              return Container(
                padding: const EdgeInsets.only(left: 14),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: _borderColor, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
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
                          name.length > 12 ? '${name.substring(0, 12)}...' : name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        Text(
                          'Student',
                          style: TextStyle(
                            fontSize: 10,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton(
                      icon: Icon(Icons.arrow_drop_down_rounded, color: _textSecondary, size: 20),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 18),
                              const SizedBox(width: 10),
                              const Text('Profile'),
                            ],
                          ),
                          onTap: () => _navigateToRoute('Profile'),
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.settings_outlined, size: 18),
                              const SizedBox(width: 10),
                              const Text('Settings'),
                            ],
                          ),
                          onTap: () => _navigateToRoute('Settings'),
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                              SizedBox(width: 10),
                              Text('Logout', style: TextStyle(color: Color(0xFFEF4444))),
                            ],
                          ),
                          onTap: () async {
                            final router = GoRouter.of(context);
                            await SessionManager.clearSession();
                            await AuthService.logout();
                            router.go('/login');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    final institutionId = _getInstitutionId();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(
          bottom: BorderSide(color: _borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.go('/$institutionId/student/dashboard'),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'Home',
                style: TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, size: 14, color: _textSecondary),
          const SizedBox(width: 6),
          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF4F46E5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(bool isMobile, bool isTablet) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (isMobile) {
              // Mobile: Single column scrollable layout
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 16),
                    _buildProgressRingsCard(),
                    const SizedBox(height: 16),
                    _buildDashboardCardsMobile(),
                    const SizedBox(height: 16),
                    _buildRecentActivity(),
                    const SizedBox(height: 16),
                    _buildTodaySchedule(),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 16),
                    _buildProgressStats(),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            }
            
            // Tablet/Desktop: Grid layout
            final topSectionHeight = 65 + 110 + 130 + 54;
            final bottomSectionHeight = constraints.maxHeight - topSectionHeight - 48;
            
            return SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 20 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(),
                  const SizedBox(height: 18),
                  _buildProgressRingsCard(),
                  const SizedBox(height: 18),
                  _buildDashboardCards(),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: bottomSectionHeight > 400 ? bottomSectionHeight : 400,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              Expanded(child: _buildRecentActivity()),
                              const SizedBox(height: 16),
                              Expanded(child: _buildTodaySchedule()),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              _buildQuickActions(),
                              const SizedBox(height: 16),
                              Expanded(child: _buildProgressStats()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardCardsMobile() {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _fetchProfile(),
      builder: (context, snapshot) {
        String branch = '';
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          branch = data?['branch'] ?? '';
        }

        final cards = [
          {
            'title': 'Current Semester',
            'value': _user?.sem ?? 'N/A',
            'icon': Icons.menu_book_rounded,
            'color': const Color(0xFF4F46E5),
            'subtext': _user?.programme ?? (branch.isNotEmpty ? branch : 'B.Tech CSE'),
          },
          {
            'title': 'CGPA',
            'value': _user?.currentGPA?.toStringAsFixed(1) ?? '8.6',
            'icon': Icons.trending_up_rounded,
            'color': const Color(0xFF10B981),
            'subtext': 'Current Standing',
          },
          {
            'title': 'Pending Tasks',
            'value': '5',
            'icon': Icons.assignment_rounded,
            'color': const Color(0xFFF59E0B),
            'subtext': '2 Assignments, 3 Tests',
          },
          {
            'title': 'Active Applications',
            'value': '8',
            'icon': Icons.business_center_rounded,
            'color': const Color(0xFF8B5CF6),
            'subtext': '3 Pending Reviews',
          },
        ];

        return Column(
          children: cards.map((card) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (card['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        card['icon'] as IconData,
                        color: card['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card['title'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card['value'] as String,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card['subtext'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: _textSecondary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildWelcomeSection() {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _fetchProfile(),
      builder: (context, snapshot) {
        String name = 'Student';
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          name = data?['name'] ?? 'Student';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $name',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Here\'s your academic and placement overview',
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressRingsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.donut_large_rounded,
              color: Color(0xFF4F46E5),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Progress Overview',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const Spacer(),
          _buildProgressRing('Attendance', _attendancePercentage, const Color(0xFF10B981)),
          const SizedBox(width: 30),
          _buildProgressRing('Assignments', (_academicSummary?['assignmentsPercentage'] as num?)?.toDouble() ?? 0.0, const Color(0xFF4F46E5)),
          const SizedBox(width: 30),
          _buildProgressRing('Credits', (_academicSummary?['creditsPercentage'] as num?)?.toDouble() ?? 0.0, const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildProgressRing(String label, double percentage, Color color) {
    return InkWell(
      onTap: () {
        if (label == 'Attendance') {
          _navigateToRoute('Attendance');
        } else if (label == 'Assignments') {
          _navigateToRoute('Assignments');
        } else if (label == 'Credits') {
          _navigateToRoute('Credits');
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CustomPaint(
                painter: _ProgressRingPainter(percentage: percentage, color: color),
                child: Center(
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: _textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCards() {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _fetchProfile(),
      builder: (context, snapshot) {
        String branch = '';
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          branch = data?['branch'] ?? '';
        }

        final cards = [
          {
            'title': 'Current Semester',
            'value': _user?.sem ?? 'N/A',
            'icon': Icons.menu_book_rounded,
            'color': const Color(0xFF4F46E5),
            'subtext': _user?.programme ?? (branch.isNotEmpty ? branch : 'B.Tech CSE'),
          },
          {
            'title': 'CGPA',
            'value': _user?.currentGPA?.toStringAsFixed(1) ?? '8.6',
            'icon': Icons.trending_up_rounded,
            'color': const Color(0xFF10B981),
            'subtext': 'Current Standing',
          },
          {
            'title': 'Pending Tasks',
            'value': '5',
            'icon': Icons.assignment_rounded,
            'color': const Color(0xFFF59E0B),
            'subtext': '2 Assignments, 3 Tests',
          },
          {
            'title': 'Active Applications',
            'value': '8',
            'icon': Icons.business_center_rounded,
            'color': const Color(0xFF8B5CF6),
            'subtext': '3 Pending Reviews',
          },
        ];

        return Row(
          children: cards.map((card) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (card['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              card['icon'] as IconData,
                              color: card['color'] as Color,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        card['value'] as String,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        card['title'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card['subtext'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: _textSecondary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      {
        'title': 'Assignment Submitted',
        'subtitle': 'Data Structures - Lab 5',
        'time': '2 hours ago',
        'icon': Icons.check_circle_outline_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'New Placement Drive',
        'subtitle': 'Google - Software Engineer',
        'time': '5 hours ago',
        'icon': Icons.business_center_rounded,
        'color': const Color(0xFF4F46E5),
      },
      {
        'title': 'Attendance Warning',
        'subtitle': 'Computer Networks - 72%',
        'time': '1 day ago',
        'icon': Icons.warning_amber_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Test Scheduled',
        'subtitle': 'Operating Systems - Unit 3',
        'time': '2 days ago',
        'icon': Icons.event_note_rounded,
        'color': const Color(0xFF8B5CF6),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Color(0xFF4F46E5),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: activities.length,
              separatorBuilder: (context, index) => Divider(
                color: _borderColor,
                height: 14,
              ),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (activity['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          activity['icon'] as IconData,
                          color: activity['color'] as Color,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['title'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activity['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        activity['time'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule() {
    if (_isLoadingSchedule) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_todaySchedule.isEmpty) {
      return const Center(child: Text('No classes scheduled for today.'));
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Today\'s Schedule',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _navigateToRoute('Timetable'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF4F46E5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: _todaySchedule.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = _todaySchedule[index];
                final slot = _allTimeSlots.firstWhere((s) => s.id == entry.timeSlotId);
                final course = _allCourses.firstWhere((c) => c.courseCode == entry.courseCode, orElse: () => Course(courseCode: '', courseName: 'Unknown', facultyUid: '', institutionId: '', program: '', semester: '', studentsEnrolled: [], totalClasses: ''));
                final room = _allRooms.firstWhere(
                  (r) => r.id == entry.roomId, 
                  orElse: () => Room(id: '', name: entry.roomId, capacity: 0, institutionId: '')
                );

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    course.courseName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Room ${room.name}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 11,
                                  color: _textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${slot.startTime} - ${slot.endTime}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _textSecondary,
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'label': 'My Mentor',
        'icon': Icons.supervisor_account_rounded,
        'color': const Color(0xFFEC4899),
        'route': 'My Mentor',
      },
      {
        'label': 'Library',
        'icon': Icons.local_library_rounded,
        'color': const Color(0xFF10B981),
        'route': 'Library',
      },
      {
        'label': 'Transport',
        'icon': Icons.directions_bus_rounded,
        'color': const Color(0xFF4F46E5),
        'route': 'Transport',
      },
      {
        'label': 'Fees',
        'icon': Icons.payment_rounded,
        'color': const Color(0xFFF59E0B),
        'route': 'Fees',
      },
      {
        'label': 'Canteen',
        'icon': Icons.restaurant_rounded,
        'color': const Color(0xFF8B5CF6),
        'route': 'Canteen',
      },
      {
        'label': 'Messages',
        'icon': Icons.message_rounded,
        'color': const Color(0xFF06B6D4),
        'route': 'Messages',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final buttonWidth = (constraints.maxWidth - 8) / 2; // 8 = spacing between buttons
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions.map((action) {
                  return InkWell(
                    onTap: () => _navigateToRoute(action['route'] as String),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: buttonWidth,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (action['color'] as Color).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            action['icon'] as IconData,
                            color: action['color'] as Color,
                            size: 16,
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              action['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStats() {
    if (_isLoadingSummary) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = [
      {
        'label': 'Assignments Completed',
        'value': '${_academicSummary?['assignmentsCompleted'] ?? 0}/${_academicSummary?['assignmentsTotal'] ?? 5}',
        'percentage': (_academicSummary?['assignmentsPercentage'] as num?)?.toDouble() ?? 0.0,
        'color': const Color(0xFF10B981),
      },
      {
        'label': 'Tests Attempted',
        'value': '${_academicSummary?['testsAttempted'] ?? 0}/${_academicSummary?['testsTotal'] ?? 3}',
        'percentage': (_academicSummary?['testsPercentage'] as num?)?.toDouble() ?? 0.0,
        'color': const Color(0xFF4F46E5),
      },
      {
        'label': 'Projects Submitted',
        'value': '${_academicSummary?['projectsSubmitted'] ?? 0}/${_academicSummary?['projectsTotal'] ?? 1}',
        'percentage': (_academicSummary?['projectsPercentage'] as num?)?.toDouble() ?? 0.0,
        'color': const Color(0xFFF59E0B),
      },
      {
        'label': 'Exam Performance',
        'value': '${(_academicSummary?['averageExamScore'] ?? 0.0).toStringAsFixed(1)}%',
        'percentage': (_academicSummary?['examsPercentage'] as num?)?.toDouble() ?? 0.0,
        'color': const Color(0xFF8B5CF6),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF4F46E5),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Academic Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: stats.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final stat = stats[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          stat['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        Text(
                          stat['value'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: stat['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (stat['percentage'] as double) / 100,
                        backgroundColor: _borderColor,
                        valueColor: AlwaysStoppedAnimation(
                          stat['color'] as Color,
                        ),
                        minHeight: 7,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Progress Ring Painter
class _ProgressRingPainter extends CustomPainter {
  final double percentage;
  final Color color;

  _ProgressRingPainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Background circle
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius - 3, backgroundPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * math.pi * (percentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 3),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}