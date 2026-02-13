import 'package:flutter/material.dart';
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

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen> {
  bool sidebarOpen = true;
  UserModel? _currentUser;
  bool _isLoadingUser = true;
  bool _isClockingIn = false;
  final ApiService _apiService = ApiService();
  String? _institutionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _institutionId = GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'];
      _fetchCurrentUser();
    });
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
    
    setState(() { _isClockingIn = true; });

    try {
      final position = await _determinePosition();
      final updatedUser = await _apiService.clockIn(_institutionId!, position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _currentUser = updatedUser;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully clocked in!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clock in: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if(mounted) {
        setState(() { _isClockingIn = false; });
      }
    }
  }

  Future<void> _handleClockOut() async {
    if (_institutionId == null) return;

    setState(() { _isClockingIn = true; });

    try {
      final position = await _determinePosition();
      final updatedUser = await _apiService.clockOut(_institutionId!, position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _currentUser = updatedUser;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully clocked out!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clock out: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if(mounted) {
        setState(() { _isClockingIn = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {'icon': Icons.home_outlined, 'label': 'Dashboard', 'active': true, 'route': null},
      {'icon': Icons.person_outline, 'label': 'Profile', 'route': '/faculty/profile'},
      {'icon': Icons.credit_card_outlined, 'label': 'Virtual ID', 'route': '/faculty/virtual-id'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Timetable', 'route': '/faculty/timetable'},
      {'icon': Icons.group_outlined, 'label': 'Mentees', 'badge': '8', 'route': '/faculty/mentees'},
      {'icon': Icons.description_outlined, 'label': 'Leave', 'route': '/faculty/leave'},
      {'icon': Icons.attach_money, 'label': 'Payroll', 'route': '/faculty/payroll'},
      {'icon': Icons.celebration_outlined, 'label': 'Events', 'route': '/faculty/events'},
      {'icon': Icons.notifications_none_outlined, 'label': 'Meetings', 'route': '/faculty/meetings'},
      {'icon': Icons.assignment_outlined, 'label': 'Mark Attendance', 'route': '/faculty/mark-attendance'},
      {'icon': Icons.history_outlined, 'label': 'Clock-in History', 'route': '/faculty/attendance-history'},
      {'icon': Icons.settings_outlined, 'label': 'Settings', 'route': '/faculty/settings'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Row(
        children: [
          // Collapsible Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: sidebarOpen ? 256 : 80,
            decoration: const BoxDecoration(
              color: Color(0xFF312E81),
            ),
            child: Column(
              children: [
                // Logo Area
                Container(
                  height: 72,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF4C1D95), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (sidebarOpen)
                        const Text(
                          'Acadexa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          sidebarOpen ? Icons.close : Icons.menu,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            sidebarOpen = !sidebarOpen;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Menu Items - Scrollable
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      final isActive = item['active'] == true;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF4C1D95) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isActive
                              ? const Border(
                                  left: BorderSide(color: Colors.white, width: 4),
                                )
                              : null,
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: sidebarOpen ? 12 : 8,
                            vertical: 4,
                          ),
                          leading: Icon(
                            item['icon'] as IconData,
                            color: Colors.white,
                            size: 20,
                          ),
                          title: sidebarOpen
                              ? Text(
                                  item['label'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                )
                              : null,
                          trailing: sidebarOpen && item['badge'] != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    item['badge'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () {
                            final institutionId = GoRouter.of(context)
                                .routerDelegate
                                .currentConfiguration
                                .pathParameters['institutionId'];
                            final route = item['route'] as String?;

                            if (route != null && institutionId != null) {
                              context.push('/$institutionId$route');
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                // Footer
                if (sidebarOpen)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFF4C1D95), width: 1),
                      ),
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
                            onPressed: () {},
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  '5',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
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

  Widget _buildClockInCard() {
    bool isClockedIn = _currentUser?.attendanceStatus == 'Clocked-in';
    String statusText = isClockedIn ? 'You are currently Clocked-in' : 'You are Clocked-out';
    String buttonText = isClockedIn ? 'Clock-out' : 'Clock-in';
    Color statusColor = isClockedIn ? Colors.green : Colors.red;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
         boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attendance Status',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
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
                      fontWeight: FontWeight.bold,
                       fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _isClockingIn ? null : (isClockedIn ? _handleClockOut : _handleClockIn),
            style: ElevatedButton.styleFrom(
              backgroundColor: isClockedIn ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
               shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isClockingIn 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
                : Text(buttonText, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtext) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 11, color: color),
          ),
          const SizedBox(height: 2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280), height: 1.2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtext,
                style: const TextStyle(fontSize: 8, color: Color(0xFF9CA3AF), height: 1.2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysScheduleCard() {
    final scheduleItems = [
      {'time': '09:00 AM', 'class': 'CSE-A', 'subject': 'Data Structures', 'room': 'Lab 301'},
      {'time': '11:00 AM', 'class': 'CSE-B', 'subject': 'Algorithms', 'room': 'Room 205'},
      {'time': '02:00 PM', 'class': 'CSE-C', 'subject': 'DBMS', 'room': 'Lab 302'},
      {'time': '04:00 PM', 'class': 'CSE-D', 'subject': 'Networks', 'room': 'Lab 201'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(Icons.calendar_today_outlined, color: Color(0xFF111827), size: 13),
              ),
              const SizedBox(width: 6),
              const Text(
                'Today\'s Schedule',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: scheduleItems.length,
              itemBuilder: (context, index) {
                final item = scheduleItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['time']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF111827)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                item['class']!,
                                style: TextStyle(color: Colors.blue.shade800, fontSize: 8, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(item['subject']!, style: const TextStyle(color: Color(0xFF111827), fontSize: 10)),
                        Text(item['room']!, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 9)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      {'title': 'Grade Assignment - CS301', 'time': 'Due Today', 'status': 'urgent', 'color': Colors.red},
      {'title': 'Student Profile Approval', 'time': '3 pending', 'status': 'pending', 'color': Colors.orange},
      {'title': 'Lecture: Algorithms', 'time': 'Today 2:00 PM', 'status': 'info', 'color': Colors.blue},
      {'title': 'Mark Attendance - CSE-A', 'time': '09:00 AM', 'status': 'info', 'color': Colors.purple},
      {'title': 'Faculty Meeting', 'time': 'Tomorrow', 'status': 'info', 'color': Colors.green},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list, size: 13, color: Color(0xFF6B7280)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: activity['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF111827),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  activity['time'] as String,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (activity['status'] == 'urgent')
                            const Icon(Icons.error_outline, size: 13, color: Colors.red),
                          if (activity['status'] == 'pending')
                            const Icon(Icons.schedule, size: 13, color: Colors.orange),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenteesOverviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(Icons.group_outlined, color: Color(0xFF111827), size: 13),
              ),
              const SizedBox(width: 6),
              const Text(
                'Mentees Overview',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Mentees', style: TextStyle(color: Color(0xFF6B7280), fontSize: 10)),
              Text('24', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF111827), fontSize: 20)),
            ],
          ),
          const SizedBox(height: 6),
          _buildMenteeRow('Excellent (90%+)', '12', Colors.green.shade600),
          const SizedBox(height: 3),
          _buildMenteeRow('Good (75-90%)', '8', Colors.blue.shade600),
          const SizedBox(height: 3),
          _buildMenteeRow('Needs Attention', '4', Colors.orange.shade600),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              final institutionId = GoRouter.of(context)
                  .routerDelegate
                  .currentConfiguration
                  .pathParameters['institutionId'];
              if (institutionId != null) {
                context.push('/$institutionId/faculty/mentees');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF3F4F6),
              foregroundColor: const Color(0xFF111827),
              elevation: 0,
              minimumSize: const Size(double.infinity, 28),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
            child: const Text('View All Mentees', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenteeRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 10)),
      ],
    );
  }

  Widget _buildEventsMeetingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(Icons.celebration_outlined, color: Color(0xFF111827), size: 13),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Events & Meetings',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  final institutionId = GoRouter.of(context)
                      .routerDelegate
                      .currentConfiguration
                      .pathParameters['institutionId'];
                  if (institutionId != null) {
                    context.push('/$institutionId/faculty/events');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                ),
                child: const Text('+ Create', style: TextStyle(fontSize: 9)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Faculty Meeting', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 11)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade200,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text('Tomorrow', style: TextStyle(color: Colors.purple.shade800, fontSize: 8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('10:00 AM | Conference Hall', style: TextStyle(color: Colors.purple.shade600, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tech Workshop', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 11)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade200,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text('Jan 10', style: TextStyle(color: Colors.blue.shade800, fontSize: 8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('Organized by: You', style: TextStyle(color: Colors.blue.shade600, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(Icons.attach_money, color: Color(0xFF111827), size: 13),
              ),
              const SizedBox(width: 6),
              const Text(
                'Payroll Summary',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Month', style: TextStyle(color: Colors.green, fontSize: 10)),
                Text('₹85,000', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 20)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Basic', style: TextStyle(color: Color(0xFF6B7280), fontSize: 9)),
                      Text('₹60,000', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827), fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Allowances', style: TextStyle(color: Color(0xFF6B7280), fontSize: 9)),
                      Text('₹25,000', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827), fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              final institutionId = GoRouter.of(context)
                  .routerDelegate
                  .currentConfiguration
                  .pathParameters['institutionId'];
              if (institutionId != null) {
                context.push('/$institutionId/faculty/payroll');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF3F4F6),
              foregroundColor: const Color(0xFF111827),
              elevation: 0,
              minimumSize: const Size(double.infinity, 28),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
            child: const Text('View Salary Slip', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    final actions = [
      {'label': 'Mark Attendance', 'color': Colors.indigo, 'route': '/faculty/mark-attendance'},
      {'label': 'View History', 'color': Colors.green, 'route': '/faculty/attendance-history'},
      {'label': 'Apply Leave', 'color': Colors.purple, 'route': '/faculty/leave'},
      {'label': 'View Payroll', 'color': Colors.orange, 'route': '/faculty/payroll'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                childAspectRatio: 2,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return ElevatedButton(
                  onPressed: () {
                    if (action['route'] != null) {
                      final institutionId = GoRouter.of(context)
                          .routerDelegate
                          .currentConfiguration
                          .pathParameters['institutionId'];
                      if (institutionId != null) {
                        context.push('/$institutionId${action['route']}');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (action['color'] as Color).withOpacity(0.1),
                    foregroundColor: action['color'] as Color,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    action['label'] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveStatusCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(Icons.description_outlined, color: Color(0xFF111827), size: 13),
              ),
              const SizedBox(width: 6),
              const Text(
                'Leave Balance',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('12', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF111827), fontSize: 18)),
                        const Text('Casual', style: TextStyle(color: Color(0xFF6B7280), fontSize: 9), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('5', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF111827), fontSize: 18)),
                        const Text('Optional', style: TextStyle(color: Color(0xFF6B7280), fontSize: 9), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('8', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF111827), fontSize: 18)),
                        const Text('Sick', style: TextStyle(color: Color(0xFF6B7280), fontSize: 9), textAlign: TextAlign.center),
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
}
