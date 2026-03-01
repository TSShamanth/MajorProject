import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/services/auth_service.dart';

class AlumniDashboardScreen extends StatefulWidget {
  const AlumniDashboardScreen({super.key});

  @override
  State<AlumniDashboardScreen> createState() => _AlumniDashboardScreenState();
}

class _AlumniDashboardScreenState extends State<AlumniDashboardScreen> {
  // ── Shell state ────────────────────────────────────────────────────────────
  bool _sidebarExpanded = true;
  bool _isDarkMode = false;
  String? _institutionId;

  // ── Theme helpers ──────────────────────────────────────────────────────────
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

  static const _accent  = Color(0xFF4F46E5);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _danger  = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _institutionId = GoRouter.of(context)
          .routerDelegate
          .currentConfiguration
          .pathParameters['institutionId'];
      setState(() {});
    });
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  void _navigateTo(String route) {
    if (_institutionId != null) {
      context.push('/$_institutionId$route');
    }
  }

  void _handleLogout() async {
    final router = GoRouter.of(context);
    await SessionManager.clearSession();
    await AuthService.logout();
    router.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
                    Expanded(child: _buildBody(isMobile: isMobile)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Sidebar ────────────────────────────────────────────────────────────────
  List<Map<String, Object?>> _menuItems() => [
        {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'active': true, 'route': '/admin/alumni-dashboard'},
        {'icon': Icons.group_outlined, 'label': 'Alumni Directory', 'active': false, 'route': '/admin/alumni-directory'},
        {'icon': Icons.work_outline, 'label': 'Job Board', 'active': false, 'route': '/admin/alumni-job-board'},
        {'icon': Icons.event_outlined, 'label': 'Events', 'active': false, 'route': '/events'},
        {'icon': Icons.favorite_border, 'label': 'Donations', 'active': false, 'route': '/admin/donations'},
        {'icon': Icons.settings_outlined, 'label': 'Settings', 'active': false, 'route': '/admin/settings'},
      ];

  Widget _buildModernSidebar() {
    final items = _menuItems();
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
      child: _sidebarExpanded
          ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1)))),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Center(
                          child: Text('A',
                              style: TextStyle(
                                  color: _isDarkMode ? const Color(0xFF1F2937) : _accent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text('Acadexa',
                            style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
                      ),
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
                    children: items.map((item) {
                      final isActive = item['active'] == true;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                        child: InkWell(
                          onTap: () {
                            final route = item['route'];
                            if (route != null) _navigateTo(route as String);
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
                                Icon(item['icon'] as IconData,
                                    color: Colors.white.withOpacity(isActive ? 1.0 : 0.7), size: 24),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(item['label'] as String,
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(isActive ? 1.0 : 0.8),
                                          fontSize: 15,
                                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                _buildSidebarFooter(),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
      child: Column(
        children: [
          _footerLink('Help', Icons.help_outline_rounded),
          _footerLink('Docs', Icons.description_outlined),
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

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: _cardColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [_accent, Color(0xFF4338CA)])),
            child: Text('Alumni Portal', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          ..._menuItems().map((item) => ListTile(
                leading: Icon(item['icon'] as IconData, color: _accent),
                title: Text(item['label'] as String, style: TextStyle(color: _textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  final route = item['route'];
                  if (route != null) _navigateTo(route as String);
                },
              )),
        ],
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────
  Widget _buildModernTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(color: _cardColor, border: Border(bottom: BorderSide(color: _borderColor))),
      child: Row(
        children: [
          if (!_sidebarExpanded)
            IconButton(icon: Icon(Icons.menu_rounded, color: _textPrimary), onPressed: () => setState(() => _sidebarExpanded = true)),
          Text('Alumni Network', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textPrimary)),
          const Spacer(),
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: _textPrimary),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
          const SizedBox(width: 16),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(onTap: _handleLogout, child: const Text('Logout')),
            ],
            child: Row(
              children: [
                CircleAvatar(backgroundColor: _accent, radius: 18, child: Text('A', style: TextStyle(color: Colors.white, fontSize: 14))),
                const SizedBox(width: 10),
                Text('Admin', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600)),
                Icon(Icons.arrow_drop_down, color: _textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTopBar() {
    return AppBar(
      title: const Text('Alumni Portal'),
      backgroundColor: _cardColor,
      foregroundColor: _textPrimary,
      actions: [
        IconButton(
          icon: Icon(_isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
          onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
        ),
      ],
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(color: _cardColor, border: Border(bottom: BorderSide(color: _borderColor))),
      child: Row(
        children: [
          Text('Home', style: TextStyle(fontSize: 14, color: _textSecondary)),
          Icon(Icons.chevron_right_rounded, size: 18, color: _textSecondary),
          Text('Dashboard', style: TextStyle(fontSize: 14, color: _accent, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody({required bool isMobile}) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Overview', style: TextStyle(fontSize: isMobile ? 22 : 26, fontWeight: FontWeight.w800, color: _textPrimary)),
          const SizedBox(height: 20),
          _buildStatsGrid(isMobile),
          const SizedBox(height: 24),
          _buildFeatureCard(
            icon: Icons.search_rounded,
            title: 'Alumni Directory',
            subtitle: 'Search and filter the entire database.',
            color: _accent,
            onTap: () => _navigateTo('/admin/alumni-directory'),
          ),
          _buildFeatureCard(
            icon: Icons.work_outline_rounded,
            title: 'Job Board',
            subtitle: 'Opportunities from alumni network.',
            color: _success,
            onTap: () => _navigateTo('/admin/alumni-job-board'),
          ),
          _buildFeatureCard(
            icon: Icons.favorite_rounded,
            title: 'Donation Campaigns',
            subtitle: 'Manage fundraising drives.',
            color: _danger,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isMobile) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 1 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 3 : 2.5,
      children: [
        _buildStatCard('Total Alumni', '1,250', Icons.group_rounded, _accent),
        _buildStatCard('Active Jobs', '42', Icons.work_rounded, _warning),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _textPrimary)),
              Text(label, style: TextStyle(fontSize: 13, color: _textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: _borderColor)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textPrimary)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 14, color: _textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
