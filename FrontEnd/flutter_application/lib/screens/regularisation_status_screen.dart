import 'package:flutter/material.dart';
import 'package:flutter_application/models/regularisation_request_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:go_router/go_router.dart';

class RegularisationStatusScreen extends StatefulWidget {
  const RegularisationStatusScreen({super.key});

  @override
  State<RegularisationStatusScreen> createState() =>
      _RegularisationStatusScreenState();
}

class _RegularisationStatusScreenState
    extends State<RegularisationStatusScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<RegularisationRequest>> _requests;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _institutionId = GoRouter.of(context)
          .routerDelegate
          .currentConfiguration
          .pathParameters['institutionId'];
      setState(() {
        _requests = _institutionId != null
            ? _apiService.getMyRegularisationRequests(_institutionId!)
            : Future.value([]);
      });
    });
    // Initialise with empty future to avoid LateInitializationError
    _requests = Future.value([]);
  }

  // ── Refresh ────────────────────────────────────────────────────────────────
  void _refresh() {
    if (_institutionId != null) {
      setState(() {
        _requests =
            _apiService.getMyRegularisationRequests(_institutionId!);
      });
    }
  }

  // ── Status colour + icon ───────────────────────────────────────────────────
  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'approved':
        return _success;
      case 'rejected':
        return _danger;
      case 'pending':
        return _warning;
      default:
        return _purple;
    }
  }

  IconData _statusIcon(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'pending':
        return Icons.access_time_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  // ── Request type colour ────────────────────────────────────────────────────
  Color _typeColor(String? type) =>
      (type ?? '').toLowerCase().contains('in') ? _success : _warning;

  IconData _typeIcon(String? type) =>
      (type ?? '').toLowerCase().contains('in')
          ? Icons.login_rounded
          : Icons.logout_rounded;

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return Scaffold(
          backgroundColor: _bgColor,
          drawer: isMobile ? _buildMobileDrawer() : null,
          body: isMobile
              ? Column(
                  children: [
                    _buildMobileTopBar(),
                    _buildMobileBreadcrumb(),
                    Expanded(child: _buildBody(isMobile: true)),
                  ],
                )
              : Row(
                  children: [
                    _buildSidebar(),
                    Expanded(
                      child: Column(
                        children: [
                          _buildTopBar(),
                          _buildBreadcrumb(),
                          Expanded(
                              child: _buildBody(isMobile: false)),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SIDEBAR
  // ══════════════════════════════════════════════════════════════════════════
  List<Map<String, Object?>> _menuItems() => [
        {
          'icon': Icons.dashboard_rounded,
          'label': 'Dashboard',
          'active': false,
          'route': null
        },
        {
          'icon': Icons.person_outline,
          'label': 'Profile',
          'active': false,
          'route': '/faculty/profile'
        },
        {
          'icon': Icons.credit_card_outlined,
          'label': 'Virtual ID',
          'active': false,
          'route': '/faculty/virtual-id'
        },
        {
          'icon': Icons.calendar_today_outlined,
          'label': 'Timetable',
          'active': false,
          'route': '/faculty/timetable'
        },
        {
          'icon': Icons.group_outlined,
          'label': 'Mentees',
          'active': false,
          'route': '/faculty/mentees'
        },
        {
          'icon': Icons.description_outlined,
          'label': 'Leave',
          'active': false,
          'route': '/faculty/leave'
        },
        {
          'icon': Icons.attach_money,
          'label': 'Payroll',
          'active': false,
          'route': '/faculty/payroll'
        },
        {
          'icon': Icons.celebration_outlined,
          'label': 'Events',
          'active': false,
          'route': '/faculty/events'
        },
        {
          'icon': Icons.notifications_none_outlined,
          'label': 'Meetings',
          'active': false,
          'route': '/faculty/meetings'
        },
        {
          'icon': Icons.assignment_outlined,
          'label': 'Mark Attendance',
          'active': false,
          'route': '/faculty/mark-attendance'
        },
        {
          'icon': Icons.history_outlined,
          'label': 'Clock-in History',
          'active': true,           // parent section is active
          'route': '/faculty/attendance-history'
        },
        {
          'icon': Icons.settings_outlined,
          'label': 'Settings',
          'active': false,
          'route': '/faculty/settings'
        },
      ];

  Widget _buildSidebar() {
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
        boxShadow: _sidebarExpanded
            ? [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(_isDarkMode ? 0.3 : 0.15),
                  blurRadius: 20,
                  offset: const Offset(4, 0),
                )
              ]
            : [],
      ),
      child: _sidebarExpanded
          ? Column(
              children: [
                // Logo header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('A',
                              style: TextStyle(
                                  color: _isDarkMode
                                      ? const Color(0xFF1F2937)
                                      : _accent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text('AcadWorkHub',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left_rounded,
                              color: Colors.white, size: 24),
                          onPressed: () =>
                              setState(() => _sidebarExpanded = false),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 0),
                    children: items.map((item) {
                      final isActive = item['active'] == true;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final route = item['route'];
                              if (route != null &&
                                  _institutionId != null) {
                                context.push(
                                    '/$_institutionId${route as String}');
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white.withOpacity(0.15)
                                    : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: isActive
                                    ? Border.all(
                                        color: Colors.white
                                            .withOpacity(0.3),
                                        width: 1)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(item['icon'] as IconData,
                                      color: Colors.white.withOpacity(
                                          isActive ? 1.0 : 0.7),
                                      size: 24),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      item['label'] as String,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(isActive
                                                ? 1.0
                                                : 0.8),
                                        fontSize: 15,
                                        fontWeight: isActive
                                            ? FontWeight.w600
                                            : FontWeight.w500,
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
                // Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: Colors.white.withOpacity(0.1))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _footerLink(
                          'Help & Support', Icons.help_outline_rounded),
                      const SizedBox(height: 4),
                      _footerLink(
                          'Documentation', Icons.description_outlined),
                    ],
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _footerLink(String label, IconData icon) => InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.white.withOpacity(0.6)),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13)),
            ],
          ),
        ),
      );

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
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                    child: Text('A',
                        style: TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.w900,
                            fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                const Text('AcadWorkHub',
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
                      color: isActive ? _accent : _textSecondary),
                  title: Text(item['label'] as String,
                      style: TextStyle(
                          color: isActive ? _accent : _textPrimary,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500)),
                  selected: isActive,
                  selectedTileColor: _accent.withOpacity(0.1),
                  onTap: () {
                    Navigator.pop(context);
                    final route = item['route'];
                    if (route != null && _institutionId != null) {
                      context.push(
                          '/$_institutionId${route as String}');
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

  // ══════════════════════════════════════════════════════════════════════════
  // TOP BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          if (!_sidebarExpanded)
            Container(
              margin: const EdgeInsets.only(right: 16),
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: _accent.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _sidebarExpanded = true),
                  borderRadius: BorderRadius.circular(12),
                  child: const Icon(Icons.menu_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
            ),

          // Page title
          const Text(
            'Regularisation Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _accent,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 16),

          // Search bar
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 18),
                  Icon(Icons.search_rounded,
                      color: _textSecondary, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search requests...',
                        hintStyle: TextStyle(
                            color: _textSecondary, fontSize: 15),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: TextStyle(
                          color: _textPrimary, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // New request button
          ElevatedButton.icon(
            onPressed: () {
              if (_institutionId != null) {
                context.push(
                    '/$_institutionId/faculty/regularisation/request');
              }
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Request',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
          const SizedBox(width: 16),

          // Dark mode toggle
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: _bgColor,
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
                    : _accent,
                size: 22,
              ),
              onPressed: () =>
                  setState(() => _isDarkMode = !_isDarkMode),
            ),
          ),
          const SizedBox(width: 16),

          // Notification bell
          Stack(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.notifications_rounded,
                      color: _textPrimary, size: 24),
                  onPressed: () {},
                ),
              ),
              Positioned(
                right: 12, top: 12,
                child: Container(
                  width: 9, height: 9,
                  decoration: const BoxDecoration(
                      color: _danger, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),

          // Avatar + popup
          Container(
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
                border: Border(
                    left: BorderSide(color: _borderColor))),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: const Center(
                    child: Text('FC',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17)),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Faculty',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary)),
                    const SizedBox(height: 2),
                    Text('Faculty Member',
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
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(children: [
                        Icon(Icons.settings_rounded,
                            size: 20, color: _textPrimary),
                        const SizedBox(width: 14),
                        Text('Settings',
                            style: TextStyle(
                                fontSize: 15, color: _textPrimary)),
                      ]),
                      onTap: () {},
                    ),
                    PopupMenuItem(
                      child: const Row(children: [
                        Icon(Icons.logout_rounded,
                            size: 20, color: _danger),
                        SizedBox(width: 14),
                        Text('Logout',
                            style: TextStyle(
                                color: _danger, fontSize: 15)),
                      ]),
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
          ),
        ],
      ),
    );
  }

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
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.menu_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Scaffold.of(context).openDrawer(),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Regularisation Status',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _accent),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              _isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: _isDarkMode
                  ? const Color(0xFFFBBF24)
                  : _accent,
            ),
            onPressed: () =>
                setState(() => _isDarkMode = !_isDarkMode),
          ),
          // New request shortcut on mobile
          Container(
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded,
                  color: Colors.white, size: 20),
              onPressed: () {
                if (_institutionId != null) {
                  context.push(
                      '/$_institutionId/faculty/regularisation/request');
                }
              },
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Breadcrumbs ────────────────────────────────────────────────────────────
  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          Text('Home',
              style: TextStyle(fontSize: 14, color: _textSecondary)),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: _textSecondary),
          const SizedBox(width: 10),
          Text('Attendance History',
              style: TextStyle(fontSize: 14, color: _textSecondary)),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: _textSecondary),
          const SizedBox(width: 10),
          const Text('Regularisation Status',
              style: TextStyle(
                  fontSize: 14,
                  color: _accent,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMobileBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          Icon(Icons.home_outlined, size: 13, color: _textSecondary),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded,
              size: 13, color: _textSecondary),
          const SizedBox(width: 4),
          Text('History',
              style: TextStyle(fontSize: 12, color: _textSecondary)),
          Icon(Icons.chevron_right_rounded,
              size: 13, color: _textSecondary),
          const SizedBox(width: 4),
          const Text('Status',
              style: TextStyle(
                  fontSize: 12,
                  color: _accent,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BODY
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBody({required bool isMobile}) {
    final padding = isMobile ? 16.0 : 28.0;

    return FutureBuilder<List<RegularisationRequest>>(
      future: _requests,
      builder: (context, snapshot) {
        return CustomScrollView(
          slivers: [
            // ── Header + summary strip ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    padding, padding, padding, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request History',
                      style: TextStyle(
                        fontSize: isMobile ? 22 : 26,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track the status of all your regularisation requests',
                      style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: _textSecondary),
                    ),
                    SizedBox(height: isMobile ? 16 : 20),

                    // Summary chips (only when data loaded)
                    if (snapshot.hasData &&
                        snapshot.data!.isNotEmpty)
                      _buildSummaryRow(snapshot.data!, isMobile),
                    SizedBox(height: isMobile ? 16 : 20),
                  ],
                ),
              ),
            ),

            // ── List ────────────────────────────────────────────────────
            if (snapshot.connectionState == ConnectionState.waiting)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: _accent),
                ),
              )
            else if (snapshot.hasError)
              SliverFillRemaining(
                child: _buildErrorState(snapshot.error.toString()),
              )
            else if (!snapshot.hasData || snapshot.data!.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    padding, 0, padding, padding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRequestCard(
                          snapshot.data![index], isMobile),
                    ),
                    childCount: snapshot.data!.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── Summary strip ──────────────────────────────────────────────────────────
  Widget _buildSummaryRow(
      List<RegularisationRequest> requests, bool isMobile) {
    final pending =
        requests.where((r) => (r.status ?? '').toLowerCase() == 'pending').length;
    final approved =
        requests.where((r) => (r.status ?? '').toLowerCase() == 'approved').length;
    final rejected =
        requests.where((r) => (r.status ?? '').toLowerCase() == 'rejected').length;

    final chips = [
      {'label': 'Total', 'count': requests.length, 'color': _accent},
      {'label': 'Pending', 'count': pending, 'color': _warning},
      {'label': 'Approved', 'count': approved, 'color': _success},
      {'label': 'Rejected', 'count': rejected, 'color': _danger},
    ];

    return isMobile
        ? GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: chips
                .map((c) => _summaryChip(
                    c['label'] as String,
                    c['count'] as int,
                    c['color'] as Color))
                .toList(),
          )
        : Row(
            children: chips
                .map((c) => Expanded(
                      child: Padding(
                        padding: chips.indexOf(c) < chips.length - 1
                            ? const EdgeInsets.only(right: 12)
                            : EdgeInsets.zero,
                        child: _summaryChip(
                            c['label'] as String,
                            c['count'] as int,
                            c['color'] as Color),
                      ),
                    ))
                .toList(),
          );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(_isDarkMode ? 0.1 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              label == 'Total'
                  ? Icons.list_alt_rounded
                  : label == 'Pending'
                      ? Icons.access_time_rounded
                      : label == 'Approved'
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Request card ───────────────────────────────────────────────────────────
  Widget _buildRequestCard(
      RegularisationRequest request, bool isMobile) {
    final statusColor = _statusColor(request.status);
    final statusIcon = _statusIcon(request.status);
    final typeColor = _typeColor(request.type);
    final typeIcon = _typeIcon(request.type);

    final dateStr =
        '${request.targetDate.toLocal()}'.split(' ')[0];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(_isDarkMode ? 0.1 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? _buildCardMobile(
              request, statusColor, statusIcon,
              typeColor, typeIcon, dateStr)
          : _buildCardDesktop(
              request, statusColor, statusIcon,
              typeColor, typeIcon, dateStr),
    );
  }

  Widget _buildCardDesktop(
    RegularisationRequest request,
    Color statusColor,
    IconData statusIcon,
    Color typeColor,
    IconData typeIcon,
    String dateStr,
  ) {
    return Row(
      children: [
        // Type icon badge
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: typeColor.withOpacity(
                _isDarkMode ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: typeColor.withOpacity(
                    _isDarkMode ? 0.3 : 0.2)),
          ),
          child: Icon(typeIcon, color: typeColor, size: 22),
        ),
        const SizedBox(width: 16),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    request.type ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _typeBadge(request.type ?? 'Unknown', typeColor),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 13, color: _textSecondary),
                  const SizedBox(width: 4),
                  Text(dateStr,
                      style: TextStyle(
                          fontSize: 13, color: _textSecondary)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                request.reason ?? '',
                style: TextStyle(
                    fontSize: 13, color: _textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Status badge
        _statusBadge(
            request.status, statusColor, statusIcon),
      ],
    );
  }

  Widget _buildCardMobile(
    RegularisationRequest request,
    Color statusColor,
    IconData statusIcon,
    Color typeColor,
    IconData typeIcon,
    String dateStr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: type icon + title + status badge
        Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(
                    _isDarkMode ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: typeColor.withOpacity(
                        _isDarkMode ? 0.3 : 0.2)),
              ),
              child: Icon(typeIcon, color: typeColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.type ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 11, color: _textSecondary),
                      const SizedBox(width: 3),
                      Text(dateStr,
                          style: TextStyle(
                              fontSize: 11,
                              color: _textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            _statusBadge(
                request.status, statusColor, statusIcon),
          ],
        ),

        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: _borderColor, height: 1),
        ),

        // Reason
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.notes_rounded,
                size: 14, color: _textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                request.reason ?? '',
                style: TextStyle(
                    fontSize: 13, color: _textSecondary),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusBadge(
      String? status, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(_isDarkMode ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: color.withOpacity(_isDarkMode ? 0.3 : 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            status ?? 'Unknown',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(String? type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(_isDarkMode ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type ?? 'Unknown',
        style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inbox_rounded,
                size: 48, color: _accent.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text(
            'No Requests Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have not submitted any regularisation requests.',
            style: TextStyle(fontSize: 14, color: _textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (_institutionId != null) {
                context.push(
                    '/$_institutionId/faculty/regularisation/request');
              }
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Request',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _danger.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded,
                size: 48, color: _danger.withOpacity(0.6)),
          ),
          const SizedBox(height: 20),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 13, color: _textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
