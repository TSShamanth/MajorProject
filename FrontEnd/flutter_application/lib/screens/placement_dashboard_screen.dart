import 'package:flutter/material.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class PlacementDashboardScreen extends StatefulWidget {
  const PlacementDashboardScreen({super.key});

  @override
  State<PlacementDashboardScreen> createState() => _PlacementDashboardScreenState();
}

class _PlacementDashboardScreenState extends State<PlacementDashboardScreen> with SingleTickerProviderStateMixin {
  String? _institutionId;
  bool _sidebarExpanded = true;
  bool _isDarkMode = false;
  late AnimationController _animationController;
  UserModel? _currentUser;

  // Placement specific stats (Mock for now)
  final int _studentsPlaced = 124;
  final int _totalCompanies = 42;
  final double _avgPackage = 8.5;
  final int _activeJobs = 15;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final institutionId = await SessionManager.getInstitutionId();
    if (mounted) {
      setState(() {
        _institutionId = institutionId;
      });
    }
    if (institutionId != null) {
      _fetchCurrentUser();
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final user = await _apiService.getMe(_institutionId!);
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarExpanded = !_sidebarExpanded;
      if (_sidebarExpanded) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
  }

  // Theme Helpers
  Color get _bgColor => _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get _cardColor => _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
  Color get _textPrimary => _isDarkMode ? Colors.white : const Color(0xFF1E293B);
  Color get _textSecondary => _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get _borderColor => _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get _sidebarColor => _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFF0F172A);
  Color get _accentColor => const Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
      backgroundColor: _bgColor,
      drawer: isMobile ? _buildMobileDrawer() : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isMobile),
                Expanded(
                  child: _buildMainContent(isMobile),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    double width = _sidebarExpanded ? 260 : 80;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      color: _sidebarColor,
      child: Column(
        children: [
          _buildSidebarHeader(),
          const SizedBox(height: 20),
          Expanded(child: _buildSidebarItems()),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 24),
          ),
          if (_sidebarExpanded) ...[
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'PLACEMENTS',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService.logout();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }

  Widget _buildSidebarItems() {
    final items = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'active': true},
      {'icon': Icons.business_rounded, 'label': 'Companies'},
      {'icon': Icons.work_outline_rounded, 'label': 'Job Posts'},
      {'icon': Icons.people_alt_rounded, 'label': 'Candidates'},
      {'icon': Icons.event_note_rounded, 'label': 'Interviews'},
      {'icon': Icons.analytics_rounded, 'label': 'Reports'},
    ];

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        bool active = item['active'] == true;

        return InkWell(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: active ? _accentColor.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  item['icon'] as IconData, 
                  color: active ? _accentColor : Colors.white60, 
                  size: 22
                ),
                if (_sidebarExpanded) ...[
                  const SizedBox(width: 16),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white60,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: IconButton(
        icon: Icon(_sidebarExpanded ? Icons.keyboard_double_arrow_left : Icons.keyboard_double_arrow_right, color: Colors.white60),
        onPressed: _toggleSidebar,
      ),
    );
  }

  Widget _buildTopBar(bool isMobile) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(icon: Icon(Icons.menu, color: _textPrimary), onPressed: () => Scaffold.of(context).openDrawer()),
          Text(
            'Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textPrimary),
          ),
          const Spacer(),
          _buildTopBarActions(),
        ],
      ),
    );
  }

  Widget _buildTopBarActions() {
    return Row(
      children: [
        IconButton(
          icon: Icon(_isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: _textSecondary),
          onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
        ),
        const SizedBox(width: 12),
        if (MediaQuery.of(context).size.width > 1024)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_currentUser?.displayName ?? 'Placement Officer', style: TextStyle(fontWeight: FontWeight.w700, color: _textPrimary, fontSize: 14)),
              Text('Placement Cell', style: TextStyle(color: _textSecondary, fontSize: 12)),
            ],
          ),
        const SizedBox(width: 12),
        PopupMenuButton<String>(
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'logout') {
              _handleLogout();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 20),
                  SizedBox(width: 12),
                  Text('My Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: Colors.redAccent.shade200, size: 20),
                  const SizedBox(width: 12),
                  const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                ],
              ),
            ),
          ],
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded, color: _accentColor),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 32),
          _buildStatGrid(isMobile),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildJobBoard()),
              if (!isMobile) ...[
                const SizedBox(width: 24),
                Expanded(child: _buildRecentActivity()),
              ],
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ]
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, ${_currentUser?.displayName ?? 'Officer'}! 👋',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Here is what\'s happening with placements today.',
          style: TextStyle(fontSize: 15, color: _textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatGrid(bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = isMobile ? 2 : 4;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('Students Placed', _studentsPlaced.toString(), Icons.school_rounded, Colors.blue, '+12%'),
            _buildStatCard('Companies', _totalCompanies.toString(), Icons.business_rounded, Colors.orange, '5 new'),
            _buildStatCard('Avg Package', '₹$_avgPackage LPA', Icons.currency_rupee_rounded, Colors.green, '+0.5L'),
            _buildStatCard('Active Jobs', _activeJobs.toString(), Icons.work_rounded, Colors.purple, '3 closing'),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String trend) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(trend, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textPrimary)),
              Text(title, style: TextStyle(fontSize: 13, color: _textSecondary, fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildJobBoard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Job Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary)),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 16),
          _buildJobItem('Google', 'Software Engineer', 'Full-time', '₹24 - 32 LPA', Colors.blue),
          _buildJobItem('Amazon', 'SDE Intern', 'Internship', '₹80k /mo', Colors.orange),
          _buildJobItem('Microsoft', 'Product Manager', 'Full-time', '₹18 - 25 LPA', Colors.blueGrey),
        ],
      ),
    );
  }

  Widget _buildJobItem(String company, String role, String type, String package, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Text(company[0], style: TextStyle(color: color, fontWeight: FontWeight.bold))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role, style: TextStyle(fontWeight: FontWeight.w700, color: _textPrimary)),
                Text(company, style: TextStyle(fontSize: 12, color: _textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(package, style: TextStyle(fontWeight: FontWeight.w600, color: _accentColor, fontSize: 13)),
              Text(type, style: TextStyle(fontSize: 11, color: _textSecondary)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary)),
          const SizedBox(height: 20),
          _buildActivityItem('Rahul Sharma placed at Google', '2h ago', Icons.check_circle_rounded, Colors.green),
          _buildActivityItem('New Job Post: Amazon SDE', '5h ago', Icons.add_box_rounded, Colors.blue),
          _buildActivityItem('Microsoft Interview scheduled', 'Yesterday', Icons.calendar_month_rounded, Colors.orange),
          _buildActivityItem('15 new candidate applications', 'Yesterday', Icons.people_rounded, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String text, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textPrimary)),
                Text(time, style: TextStyle(fontSize: 11, color: _textSecondary)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: _sidebarColor,
      child: Column(
        children: [
          _buildSidebarHeader(),
          const SizedBox(height: 20),
          Expanded(child: _buildSidebarItems()),
        ],
      ),
    );
  }
}
