import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/services/auth_service.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final List<Widget>? breadcrumbs;

  const AdminLayout({
    super.key,
    required this.child,
    this.title = 'Dashboard',
    this.breadcrumbs,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  bool _sidebarExpanded = true;
  bool _isDarkMode = false;
  String? _institutionId;

  @override
  void initState() {
    super.initState();
    _fetchInstitutionId();
  }

  Future<void> _fetchInstitutionId() async {
    final id = await SessionManager.getInstitutionId();
    if (mounted) {
      setState(() {
        _institutionId = id;
      });
    }
  }

  Color get _bgColor => _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
  Color get _cardColor => _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
  Color get _textPrimary => _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
  Color get _textSecondary => _isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get _borderColor => _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return Scaffold(
          backgroundColor: _bgColor,
          drawer: isMobile ? _buildMobileDrawer() : null,
          body: isMobile
              ? _buildMobileLayout()
              : Row(
                  children: [
                    _buildModernSidebar(),
                    Expanded(
                      child: Column(
                        children: [
                          _buildModernTopBar(),
                          _buildBreadcrumb(),
                          Expanded(child: widget.child),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildMobileTopBar(),
        _buildBreadcrumb(),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildMobileTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
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
              color: _isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFF4F46E5),
            ),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: _cardColor,
      child: _buildSidebarContent(),
    );
  }

  Widget _buildModernSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _sidebarExpanded ? 270 : 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode
              ? [const Color(0xFF1F2937), const Color(0xFF111827)]
              : [const Color(0xFF4F46E5), const Color(0xFF4338CA)],
        ),
      ),
      child: _buildSidebarContent(),
    );
  }

  Widget _buildSidebarContent() {
    final menuItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'route': '/admin/dashboard'},
      {'icon': Icons.people_rounded, 'label': 'User Management', 'route': '/admin/users/student'},
      {'icon': Icons.settings_applications_rounded, 'label': 'Institution Setup', 'route': '/admin/institution-settings'},
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Fee Management', 'route': '/admin/fee-management'},
      {'icon': Icons.school_rounded, 'label': 'Academic Operations', 'route': null},
      {'icon': Icons.approval, 'label': 'Approval', 'route': '/admin/approval'},
      {'icon': Icons.announcement_rounded, 'label': 'Announcements', 'route': '/announcements/manage'},
      {'icon': Icons.settings_rounded, 'label': 'System Settings', 'route': null},
    ];

    final currentPath = GoRouterState.of(context).uri.toString();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: const Color(0xFF4F46E5),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              if (_sidebarExpanded) ...[
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AcadWorkHub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: menuItems.map((item) {
              final route = item['route'] as String?;
              final bool isActive = route != null && currentPath.contains(route);
              
              return ListTile(
                leading: Icon(
                  item['icon'] as IconData,
                  color: Colors.white.withOpacity(isActive ? 1.0 : 0.7),
                ),
                title: _sidebarExpanded
                    ? Text(
                        item['label'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(isActive ? 1.0 : 0.8),
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      )
                    : null,
                onTap: () {
                  if (route != null && _institutionId != null) {
                    context.go('/$_institutionId$route');
                  }
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                selected: isActive,
                selectedTileColor: Colors.white.withOpacity(0.1),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildModernTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_sidebarExpanded ? Icons.menu_open : Icons.menu, color: _textPrimary),
            onPressed: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
          ),
          const SizedBox(width: 16),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: _textPrimary,
            ),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            backgroundColor: const Color(0xFF4F46E5),
            child: const Text('AD', style: TextStyle(color: Colors.white)),
          ),
          PopupMenuButton(
            icon: Icon(Icons.arrow_drop_down, color: _textSecondary),
            itemBuilder: (_) => [
              PopupMenuItem(
                child: const Text('Logout'),
                onTap: () async {
                  await SessionManager.clearSession();
                  await AuthService.logout();
                  if (mounted) context.go('/login');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              if (_institutionId != null) context.go('/$_institutionId/admin/dashboard');
            },
            child: Text('Home', style: TextStyle(color: _textSecondary, fontSize: 13)),
          ),
          Icon(Icons.chevron_right, size: 16, color: _textSecondary),
          InkWell(
            onTap: () {
              if (_institutionId != null) context.go('/$_institutionId/admin/dashboard');
            },
            child: Text('Dashboard', style: TextStyle(color: _textSecondary, fontSize: 13)),
          ),
          if (widget.breadcrumbs != null) ...widget.breadcrumbs!,
        ],
      ),
    );
  }
}
