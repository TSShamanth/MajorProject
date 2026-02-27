import 'package:flutter/material.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import '../screens/global_search_bar.dart';
import '../models/course_model.dart';
import '../models/timetable_entry_model.dart';
import '../models/time_slot_model.dart';
import '../services/timetable_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FACULTY SEARCH DATA SOURCE
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

    // ── 1. PAGES ────────────────────────────────────────────────────────────
    final pages = [
      {'label': 'Dashboard', 'sub': 'Home overview', 'icon': Icons.dashboard_rounded, 'color': const Color(0xFF4F46E5), 'route': '/faculty/dashboard'},
      {'label': 'Profile', 'sub': 'View & edit your profile', 'icon': Icons.person_outline, 'color': const Color(0xFF4F46E5), 'route': '/faculty/profile'},
      {'label': 'Virtual ID', 'sub': 'Your digital faculty ID card', 'icon': Icons.credit_card_outlined, 'color': const Color(0xFF4F46E5), 'route': '/faculty/virtual-id'},
      {'label': 'Timetable', 'sub': 'Weekly class schedule', 'icon': Icons.calendar_today_outlined, 'color': const Color(0xFF4F46E5), 'route': '/faculty/timetable'},
      {'label': 'Mentees', 'sub': 'Students under your mentorship', 'icon': Icons.group_outlined, 'color': const Color(0xFF10B981), 'route': '/faculty/mentees'},
      {'label': "Students' Fee Status", 'sub': 'Check student fee records', 'icon': Icons.payments_outlined, 'color': const Color(0xFF10B981), 'route': '/faculty/student-fees'},
      {'label': 'Leave', 'sub': 'Apply for leave', 'icon': Icons.description_outlined, 'color': const Color(0xFF8B5CF6), 'route': '/faculty/leave'},
      {'label': 'Approve Leaves', 'sub': 'Review student leave requests', 'icon': Icons.check_circle_outline, 'color': const Color(0xFF8B5CF6), 'route': '/faculty/leave-approval'},
      {'label': 'Marks Entry', 'sub': 'Enter & submit student marks', 'icon': Icons.grade_outlined, 'color': const Color(0xFFF59E0B), 'route': '/faculty/marks-entry'},
      {'label': 'Payroll', 'sub': 'Salary & payslip details', 'icon': Icons.attach_money, 'color': const Color(0xFF10B981), 'route': '/faculty/payroll'},
      {'label': 'Events', 'sub': 'Campus events & meetings', 'icon': Icons.celebration_outlined, 'color': const Color(0xFF8B5CF6), 'route': '/events'},
      {'label': 'Mark Attendance', 'sub': 'Record class attendance', 'icon': Icons.assignment_turned_in_rounded, 'color': const Color(0xFF4F46E5), 'route': '/faculty/mark-attendance'},
      {'label': 'Clock-in History', 'sub': 'View your attendance log', 'icon': Icons.history_outlined, 'color': const Color(0xFF10B981), 'route': '/faculty/attendance-history'},
      {'label': 'Announcements', 'sub': 'Institution announcements', 'icon': Icons.announcement_outlined, 'color': const Color(0xFF4F46E5), 'route': '/announcements'},
    ];

    for (final p in pages) {
      if (p['label']!.toString().toLowerCase().contains(q) || p['sub']!.toString().toLowerCase().contains(q)) {
        results.add(SearchResult(
          id: 'page_${p['label']}',
          title: p['label']! as String,
          subtitle: p['sub']! as String,
          category: 'Pages',
          icon: p['icon']! as IconData,
          iconColor: p['color']! as Color,
          route: '/$institutionId${p['route']}',
        ));
      }
    }

    // ── 2. COURSES ──────────────────────────────────────────────────────────
    for (final c in courses) {
      if (c.courseName.toLowerCase().contains(q) || c.courseCode.toLowerCase().contains(q)) {
        results.add(SearchResult(
          id: c.courseCode,
          title: c.courseName,
          subtitle: '${c.courseCode}  •  ${c.program}',
          category: 'Courses',
          icon: Icons.book_outlined,
          iconColor: const Color(0xFF4F46E5),
          route: '/$institutionId/faculty/mark-attendance',
        ));
      }
    }

    // ── 3. MENTEES ──────────────────────────────────────────────────────────
    for (final m in mentees) {
      if (m.displayName.toLowerCase().contains(q) || (m.email?.toLowerCase() ?? '').contains(q)) {
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

class FacultyShell extends StatefulWidget {
  final Widget child;
  final String title;

  const FacultyShell({
    super.key,
    required this.child,
    this.title = 'Dashboard',
  });

  @override
  State<FacultyShell> createState() => _FacultyShellState();
}

class _FacultyShellState extends State<FacultyShell> {
  bool _sidebarExpanded = true;
  bool _isDarkMode = false;
  UserModel? _currentUser;
  bool _isLoadingUser = true;
  final ApiService _apiService = ApiService();
  String? _institutionId;
  int _notificationCount = 0;

  // Search data source state
  List<Course> _allCourses = [];
  List<TimetableEntry> _todaySchedule = [];
  List<TimeSlot> _allTimeSlots = [];
  List<UserModel> _mentees = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _institutionId = GoRouter.of(context)
          .routerDelegate
          .currentConfiguration
          .pathParameters['institutionId'];
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (_institutionId == null) return;
    try {
      final user = await _apiService.getMe(_institutionId!);
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _isLoadingUser = false;
      });
      _fetchNotificationCount();
      _fetchSearchData();
    } catch (e) {
      if (mounted) setState(() => _isLoadingUser = false);
    }
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

  Future<void> _fetchSearchData() async {
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
        _apiService.getRooms(_institutionId!),
        _apiService.getUsers(_institutionId!),
        timetableService.getTimeSlots(_institutionId!),
        timetableService.getTimetableForFaculty(_institutionId!, _currentUser!.uid),
        if (_currentUser!.departmentId != null)
          _apiService.getCourses(_institutionId!, _currentUser!.departmentId!)
        else
          Future.value(<Course>[]),
      ]);

      if (mounted) {
        setState(() {
          final allUsers = results[1] as List<UserModel>;
          _mentees = allUsers
              .where((u) =>
                  u.role == 'student' &&
                  u.mentorName == _currentUser!.displayName)
              .toList();
          _allTimeSlots = results[2] as List<TimeSlot>;
          final allEntries = results[3] as List<TimetableEntry>;
          _todaySchedule = allEntries.where((e) => e.day == todayName).toList();
          _allCourses = results[4] as List<Course>;
        });
      }
    } catch (e) {
      debugPrint('Error fetching search data: $e');
    }
  }

  _FacultySearchDataSource get _searchDataSource => _FacultySearchDataSource(
    institutionId: _institutionId ?? '',
    courses: _allCourses,
    todaySchedule: _todaySchedule,
    timeSlots: _allTimeSlots,
    mentees: _mentees,
  );

  void _onSearchResultTap(String route) {
    if (route.isNotEmpty) context.push(route);
  }

  Color get _bgColor => _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
  Color get _cardColor => _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
  Color get _textPrimary => _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
  Color get _textSecondary => _isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get _borderColor => _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

  List<Map<String, Object?>> _menuItems() {
    final currentPath = GoRouterState.of(context).uri.toString();
    return [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'route': '/faculty/dashboard'},
      {'icon': Icons.person_outline, 'label': 'Profile', 'route': '/faculty/profile'},
      {'icon': Icons.credit_card_outlined, 'label': 'Virtual ID', 'route': '/faculty/virtual-id'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Timetable', 'route': '/faculty/timetable'},
      {'icon': Icons.group_outlined, 'label': 'Mentees', 'badge': '8', 'route': '/faculty/mentees'},
      {'icon': Icons.payments_outlined, 'label': "Students' Fee Status", 'route': '/faculty/student-fees'},
      {'icon': Icons.description_outlined, 'label': 'Leave', 'route': '/faculty/leave'},
      {'icon': Icons.check_circle_outline, 'label': 'Approve Leaves', 'route': '/faculty/leave-approval'},
      {'icon': Icons.grade_outlined, 'label': 'Marks Entry', 'route': '/faculty/marks-entry'},
      {'icon': Icons.attach_money, 'label': 'Payroll', 'route': '/faculty/payroll'},
      {'icon': Icons.celebration_outlined, 'label': 'Events', 'route': '/events'},
      {'icon': Icons.assignment_outlined, 'label': 'Mark Attendance', 'route': '/faculty/mark-attendance'},
      {'icon': Icons.history_outlined, 'label': 'Clock-in History', 'route': '/faculty/attendance-history'},
      {'icon': Icons.announcement_outlined, 'label': 'Announcements', 'route': '/announcements'},
    ].map((item) {
      final route = item['route'] as String;
      final fullRoute = _institutionId != null ? '/$_institutionId$route' : route;
      return {
        ...item,
        'active': currentPath.startsWith(fullRoute),
      };
    }).toList();
  }

  void _handleLogout() async {
    final router = GoRouter.of(context);
    await SessionManager.clearSession();
    await AuthService.logout();
    router.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 768;
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
                        : widget.child,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

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
      ),
      child: _sidebarExpanded ? Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Text('A', style: TextStyle(
                      color: _isDarkMode ? const Color(0xFF1F2937) : const Color(0xFF4F46E5),
                      fontWeight: FontWeight.w900, fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(child: Text('AcadWorkHub', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700))),
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                  onPressed: () => setState(() => _sidebarExpanded = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: menuItems.map((item) => _buildSidebarItem(item)).toList(),
            ),
          ),
          _buildSidebarFooter(),
        ],
      ) : const SizedBox.shrink(),
    );
  }

  Widget _buildSidebarItem(Map<String, Object?> item) {
    final isActive = item['active'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: () {
          final route = item['route'] as String;
          if (_institutionId != null) context.push('/$_institutionId$route');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(item['icon'] as IconData, color: Colors.white.withOpacity(isActive ? 1.0 : 0.7), size: 24),
              const SizedBox(width: 16),
              Expanded(child: Text(item['label'] as String, style: TextStyle(
                color: Colors.white.withOpacity(isActive ? 1.0 : 0.8),
                fontSize: 15, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500))),
              if (item['badge'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(10)),
                  child: Text(item['badge'] as String, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
      child: Column(
        children: [
          _footerLink('Help & Support', Icons.help_outline_rounded),
          _footerLink('Documentation', Icons.description_outlined),
        ],
      ),
    );
  }

  Widget _footerLink(String label, IconData icon) => InkWell(
    onTap: () {},
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withOpacity(0.6)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
        ],
      ),
    ),
  );

  Widget _buildModernTopBar() {
    final displayName = _currentUser?.displayName ?? 'Faculty';
    final initials = displayName.length >= 2 ? displayName.substring(0, 2).toUpperCase() : 'FC';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(color: _cardColor, border: Border(bottom: BorderSide(color: _borderColor))),
      child: Row(
        children: [
          if (!_sidebarExpanded)
            IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => setState(() => _sidebarExpanded = true)),
          const Text('Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(width: 20),
          Expanded(
            child: GlobalSearchBar(
              isDarkMode: _isDarkMode,
              height: 46,
              hintText: 'Search students, courses...',
              dataSource: _searchDataSource,
              onNavigate: _onSearchResultTap,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
          const SizedBox(width: 16),
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.notifications_rounded), onPressed: () {
                if (_institutionId != null) {
                  context.push('/$_institutionId/notifications');
                  setState(() => _notificationCount = 0);
                }
              }),
              if (_notificationCount > 0)
                Positioned(right: 12, top: 12, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
            ],
          ),
          const SizedBox(width: 16),
          _buildProfileDropdown(displayName, initials),
        ],
      ),
    );
  }

  Widget _buildProfileDropdown(String name, String initials) {
    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
            onTap: () {
              if (_institutionId != null) {
                context.push('/$_institutionId/faculty/profile');
              }
            },
            child: const Text('Profile')),
        PopupMenuItem(onTap: _handleLogout, child: const Text('Logout')),
      ],
      child: Row(
        children: [
          CircleAvatar(
              backgroundColor: const Color(0xFF4F46E5),
              child: Text(initials,
                  style: const TextStyle(color: Colors.white))),
          const SizedBox(width: 10),
          Text(name,
              style: TextStyle(
                  color: _textPrimary, fontWeight: FontWeight.w600)),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() => Drawer(
    child: ListView(
      children: _menuItems().map((item) => ListTile(
        leading: Icon(item['icon'] as IconData),
        title: Text(item['label'] as String),
        onTap: () {
          Navigator.pop(context);
          final route = item['route'] as String;
          if (_institutionId != null) context.push('/$_institutionId$route');
        },
      )).toList()
    )
  );

  Widget _buildMobileTopBar() => AppBar(title: Text(widget.title));

  Widget _buildBreadcrumb() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    child: Row(children: [
      Text('Home', style: TextStyle(color: _textSecondary)),
      const Icon(Icons.chevron_right, size: 16),
      Text(widget.title, style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
    ]),
  );
}
