import 'package:flutter/material.dart';
import 'package:flutter_application/models/time_slot_model.dart';
import 'package:flutter_application/models/timetable_entry_model.dart';
import 'package:flutter_application/services/timetable_service.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';

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
  bool _isLoadingSchedule = true;

  @override
  void initState() {
    super.initState();
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
      setState(() => _isLoadingUser = false);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services disabled.');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Permission denied.');
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

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) context.go('/login');
  }

  Color get _bgColor => _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
  Color get _cardColor => _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
  Color get _textPrimary => _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
  Color get _textSecondary => _isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get _borderColor => _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

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

  Widget _buildModernSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _sidebarExpanded ? 260 : 88,
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF111827) : const Color(0xFF1E1B4B),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Icon(Icons.school_rounded, color: Colors.white, size: 32),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: _menuItems().map((item) => _buildSidebarItem(item)).toList(),
            ),
          ),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(Map<String, Object?> item) {
    bool isActive = item['active'] == true;
    return ListTile(
      leading: Icon(item['icon'] as IconData, color: isActive ? Colors.white : Colors.white54),
      title: _sidebarExpanded ? Text(item['label'] as String, style: const TextStyle(color: Colors.white, fontSize: 14)) : null,
      onTap: () {
        final route = item['route'] as String?;
        if (route != null && _institutionId != null) context.push('/$_institutionId$route');
      },
    );
  }

  Widget _buildSidebarFooter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: IconButton(icon: const Icon(Icons.logout, color: Colors.white54), onPressed: _handleLogout),
    );
  }

  Widget _buildModernTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: _cardColor, border: Border(bottom: BorderSide(color: _borderColor))),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_sidebarExpanded ? Icons.menu_open : Icons.menu),
            onPressed: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
          ),
          const Text('Faculty Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: _cardColor, border: Border(bottom: BorderSide(color: _borderColor))),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()),
          const Text('RVU Faculty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(child: Center(child: Text('RVU Portal', style: TextStyle(fontSize: 24)))),
          ..._menuItems().map((item) => ListTile(
            leading: Icon(item['icon'] as IconData),
            title: Text(item['label'] as String),
            onTap: () {
              Navigator.pop(context);
              final route = item['route'] as String?;
              if (route != null && _institutionId != null) context.push('/$_institutionId$route');
            },
          )),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(children: [
        Icon(Icons.home, size: 16, color: _textSecondary),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right, size: 16, color: _textSecondary),
        const SizedBox(width: 8),
        const Text('Dashboard', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildDashboardContent(bool isMobile, bool isTablet, bool isDesktop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, ${_currentUser?.displayName ?? '...'}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(height: 16),
          _buildClockInCard(),
          const SizedBox(height: 24),
          _buildResponsiveStatsRow(isMobile),
          const SizedBox(height: 24),
          _buildResponsiveMainContent(isMobile, isTablet),
        ],
      ),
    );
  }

  Widget _buildClockInCard() {
    final isClockedIn = _currentUser?.attendanceStatus == 'Clocked-in';
    final statusColor = isClockedIn ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: _borderColor)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Attendance Status', style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary)),
              Text(isClockedIn ? 'Currently Clocked-in' : 'Currently Clocked-out', style: TextStyle(color: _textSecondary)),
            ],
          ),
          ElevatedButton(
            onPressed: _isClockingIn ? null : (isClockedIn ? _handleClockOut : _handleClockIn),
            style: ElevatedButton.styleFrom(backgroundColor: statusColor, foregroundColor: Colors.white),
            child: _isClockingIn ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isClockedIn ? 'Clock Out' : 'Clock In'),
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

  Widget _buildStatCard(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: _borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textPrimary)),
          Text(title, style: TextStyle(color: _textSecondary, fontSize: 13)),
          Text(sub, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildResponsiveMainContent(bool isMobile, bool isTablet) {
    if (isMobile) {
      return Column(children: [
        _buildTodaysScheduleCard(),
        const SizedBox(height: 16),
        _buildQuickActionsCard(),
        const SizedBox(height: 16),
        _buildRecentActivity(),
      ]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: Column(children: [_buildTodaysScheduleCard(), const SizedBox(height: 16), _buildRecentActivity()])),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: Column(children: [_buildQuickActionsCard(), const SizedBox(height: 16), _buildPayrollSummaryCard()])),
      ],
    );
  }

  Widget _buildTodaysScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: _borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Schedule", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_isLoadingSchedule) const Center(child: CircularProgressIndicator())
          else if (_todaySchedule.isEmpty) const Text('No classes today')
          else ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _todaySchedule.length,
            itemBuilder: (context, index) {
              final e = _todaySchedule[index];
              final s = _allTimeSlots.firstWhere((slot) => slot.id == e.timeSlotId);
              return ListTile(
                title: Text(e.courseCode),
                subtitle: Text('${s.startTime} - ${s.endTime}'),
                trailing: const Icon(Icons.chevron_right),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: _borderColor)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Text('• Attendance marked for CS401'),
          Text('• New mentee concern received'),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: _borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              ElevatedButton(onPressed: () {}, child: const Text('Attendance')),
              ElevatedButton(onPressed: () {}, child: const Text('Marks')),
              ElevatedButton(onPressed: () {}, child: const Text('Leave')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: _borderColor)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payroll', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('₹85,000', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }

  List<Map<String, Object?>> _menuItems() {
    return [
      {'icon': Icons.dashboard, 'label': 'Dashboard', 'active': true, 'route': null},
      {'icon': Icons.person, 'label': 'Profile', 'active': false, 'route': '/faculty/profile'},
      {'icon': Icons.calendar_today, 'label': 'Timetable', 'active': false, 'route': '/faculty/timetable'},
      {'icon': Icons.group, 'label': 'Mentees', 'active': false, 'route': '/faculty/mentees'},
      {'icon': Icons.description, 'label': 'Leave', 'active': false, 'route': '/faculty/leave'},
    ];
  }
}
