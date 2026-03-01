import 'package:flutter/material.dart';
import 'package:flutter_application/models/attendance_log_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/screens/regularisation_dialog.dart';
import 'package:go_router/go_router.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  // ── Data ───────────────────────────────────────────────────────────────────
  final ApiService _apiService = ApiService();
  String? _institutionId;
  List<AttendanceLog> _history = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ── Shell state ────────────────────────────────────────────────────────────
  bool _sidebarExpanded = true;
  bool _isDarkMode = false;

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

  static const _accent   = Color(0xFF4F46E5);
  static const _success  = Color(0xFF10B981);
  static const _warning  = Color(0xFFF59E0B);
  static const _danger   = Color(0xFFEF4444);

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getInstitutionIdAndFetchHistory();
    });
  }

  Future<void> _getInstitutionIdAndFetchHistory() async {
    if (!mounted) return;
    final pathParams = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .pathParameters;
    _institutionId = pathParams['institutionId'];

    if (_institutionId == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Institution ID not found.';
          _isLoading = false;
        });
      }
      return;
    }
    await _fetchAttendanceHistory();
  }

  Future<void> _fetchAttendanceHistory() async {
    if (_institutionId == null) return;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final history =
          await _apiService.getAttendanceHistory(_institutionId!);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load history: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ── Regularisation dialog — unchanged ─────────────────────────────────────
  void _showRegularisationDialog(AttendanceLog log) {
    showDialog(
      context: context,
      builder: (context) => RegularisationDialog(log: log),
    );
  }

  // ── Log card colour logic — preserved exactly ──────────────────────────────
  Color _cardBgColor(AttendanceLog log) {
    final isRegularised = log.regularisationStatus == 'Regularised';
    final isOnCampus = log.locationStatus == 'On-Campus';
    if (isRegularised) {
      return _isDarkMode
          ? _warning.withOpacity(0.15)
          : const Color(0xFFFEF3C7);
    }
    if (isOnCampus) {
      return _isDarkMode
          ? _success.withOpacity(0.12)
          : const Color(0xFFECFDF5);
    }
    return _isDarkMode
        ? _danger.withOpacity(0.12)
        : const Color(0xFFFEF2F2);
  }

  Color _cardBorderColor(AttendanceLog log) {
    final isRegularised = log.regularisationStatus == 'Regularised';
    final isOnCampus = log.locationStatus == 'On-Campus';
    if (isRegularised) {
      return _isDarkMode
          ? _warning.withOpacity(0.4)
          : _warning.withOpacity(0.5);
    }
    if (isOnCampus) {
      return _isDarkMode
          ? _success.withOpacity(0.35)
          : _success.withOpacity(0.4);
    }
    return _isDarkMode
        ? _danger.withOpacity(0.35)
        : _danger.withOpacity(0.4);
  }

  Color _cardAccentColor(AttendanceLog log) {
    final isRegularised = log.regularisationStatus == 'Regularised';
    final isOnCampus = log.locationStatus == 'On-Campus';
    if (isRegularised) return _warning;
    if (isOnCampus) return _success;
    return _danger;
  }

  IconData _locationIcon(AttendanceLog log) {
    final isRegularised = log.regularisationStatus == 'Regularised';
    final isOnCampus = log.locationStatus == 'On-Campus';
    if (isRegularised) return Icons.info_rounded;
    if (isOnCampus) return Icons.check_circle_rounded;
    return Icons.warning_rounded;
  }

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
        {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'active': false, 'route': null},
        {'icon': Icons.person_outline, 'label': 'Profile', 'active': false, 'route': '/faculty/profile'},
        {'icon': Icons.credit_card_outlined, 'label': 'Virtual ID', 'active': false, 'route': '/faculty/virtual-id'},
        {'icon': Icons.calendar_today_outlined, 'label': 'Timetable', 'active': false, 'route': '/faculty/timetable'},
        {'icon': Icons.group_outlined, 'label': 'Mentees', 'active': false, 'route': '/faculty/mentees'},
        {'icon': Icons.description_outlined, 'label': 'Leave', 'active': false, 'route': '/faculty/leave'},
        {'icon': Icons.attach_money, 'label': 'Payroll', 'active': false, 'route': '/faculty/payroll'},
        {'icon': Icons.celebration_outlined, 'label': 'Events', 'active': false, 'route': '/faculty/events'},
        {'icon': Icons.notifications_none_outlined, 'label': 'Meetings', 'active': false, 'route': '/faculty/meetings'},
        {'icon': Icons.assignment_outlined, 'label': 'Mark Attendance', 'active': false, 'route': '/faculty/mark-attendance'},
        {'icon': Icons.history_outlined, 'label': 'Clock-in History', 'active': true, 'route': '/faculty/attendance-history'},
        {'icon': Icons.settings_outlined, 'label': 'Settings', 'active': false, 'route': '/faculty/settings'},
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
            ? [BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.15), blurRadius: 20, offset: const Offset(4, 0))]
            : [],
      ),
      child: _sidebarExpanded
          ? Column(
              children: [
                // Header
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
                            style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                      ),
                      Container(
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
                          onPressed: () => setState(() => _sidebarExpanded = false),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: items.map((item) {
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
                                color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: isActive ? Border.all(color: Colors.white.withOpacity(0.3)) : null,
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
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _footerLink('Help & Support', Icons.help_outline_rounded),
                      const SizedBox(height: 4),
                      _footerLink('Documentation', Icons.description_outlined),
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
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
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
                gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF4338CA)])),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('A', style: TextStyle(color: _accent, fontWeight: FontWeight.w900, fontSize: 22))),
                ),
                const SizedBox(width: 14),
                const Text('Acadexa',
                    style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _menuItems().map((item) {
                final isActive = item['active'] == true;
                return ListTile(
                  leading: Icon(item['icon'] as IconData, color: isActive ? _accent : _textSecondary),
                  title: Text(item['label'] as String,
                      style: TextStyle(
                          color: isActive ? _accent : _textPrimary,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500)),
                  selected: isActive,
                  selectedTileColor: _accent.withOpacity(0.1),
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

  // ══════════════════════════════════════════════════════════════════════════
  // TOP BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
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
                boxShadow: [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _sidebarExpanded = true),
                  borderRadius: BorderRadius.circular(12),
                  child: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),

          // Page title
          const Text(
            'Attendance History',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _accent, letterSpacing: -0.3),
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
                  Icon(Icons.search_rounded, color: _textSecondary, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search attendance records...',
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

          // Regularize button (replaces old green AppBar action)
          ElevatedButton.icon(
            onPressed: () {
              if (_institutionId != null) {
                context.push('/$_institutionId/faculty/regularisation');
              }
            },
            icon: const Icon(Icons.edit_calendar_rounded, size: 18),
            label: const Text('Regularize', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: _isDarkMode ? const Color(0xFFFBBF24) : _accent,
                size: 22,
              ),
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
            ),
          ),
          const SizedBox(width: 16),

          // Notification bell
          Stack(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  icon: Icon(Icons.notifications_rounded, color: _textPrimary, size: 24),
                  onPressed: () {},
                ),
              ),
              Positioned(
                right: 12, top: 12,
                child: Container(
                  width: 9, height: 9,
                  decoration: const BoxDecoration(color: _danger, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),

          // Avatar + popup
          Container(
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(border: Border(left: BorderSide(color: _borderColor))),
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
                    child: Text('FC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Faculty', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary)),
                    const SizedBox(height: 2),
                    Text('Faculty Member', style: TextStyle(fontSize: 13, color: _textSecondary)),
                  ],
                ),
                const SizedBox(width: 10),
                PopupMenuButton(
                  icon: Icon(Icons.arrow_drop_down_rounded, color: _textSecondary, size: 26),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: _cardColor,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(children: [
                        Icon(Icons.settings_rounded, size: 20, color: _textPrimary),
                        const SizedBox(width: 14),
                        Text('Settings', style: TextStyle(fontSize: 15, color: _textPrimary)),
                      ]),
                      onTap: () {},
                    ),
                    PopupMenuItem(
                      child: const Row(children: [
                        Icon(Icons.logout_rounded, size: 20, color: _danger),
                        SizedBox(width: 14),
                        Text('Logout', style: TextStyle(color: _danger, fontSize: 15)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(10)),
              child: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                onPressed: () => Scaffold.of(context).openDrawer(),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Attendance History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _accent),
                overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: _isDarkMode ? const Color(0xFFFBBF24) : _accent,
            ),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
          // Regularize shortcut on mobile
          Container(
            decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(8)),
            child: IconButton(
              icon: const Icon(Icons.edit_calendar_rounded, color: Colors.white, size: 20),
              onPressed: () {
                if (_institutionId != null) {
                  context.push('/$_institutionId/faculty/regularisation');
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
          Text('Home', style: TextStyle(fontSize: 14, color: _textSecondary)),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right_rounded, size: 18, color: _textSecondary),
          const SizedBox(width: 10),
          const Text('Attendance History',
              style: TextStyle(fontSize: 14, color: _accent, fontWeight: FontWeight.w600)),
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
          Icon(Icons.chevron_right_rounded, size: 13, color: _textSecondary),
          const SizedBox(width: 4),
          const Text('Attendance History',
              style: TextStyle(fontSize: 12, color: _accent, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BODY
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBody({required bool isMobile}) {
    final padding = isMobile ? 16.0 : 28.0;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _accent));
    }

    if (_errorMessage != null) {
      return _buildErrorState(padding);
    }

    if (_history.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _fetchAttendanceHistory,
      color: _accent,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page heading
                  Text(
                    'Clock-in History',
                    style: TextStyle(
                      fontSize: isMobile ? 22 : 26,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap any record to submit a regularisation request',
                    style: TextStyle(fontSize: isMobile ? 13 : 14, color: _textSecondary),
                  ),
                  SizedBox(height: isMobile ? 16 : 20),

                  // Summary strip
                  _buildSummaryStrip(isMobile),
                  SizedBox(height: isMobile ? 16 : 20),

                  // Legend
                  _buildLegend(isMobile),
                  SizedBox(height: isMobile ? 12 : 16),
                ],
              ),
            ),
          ),

          // Log list
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final log = _history[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildLogCard(log, isMobile),
                  );
                },
                childCount: _history.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary strip ──────────────────────────────────────────────────────────
  Widget _buildSummaryStrip(bool isMobile) {
    final total = _history.length;
    final onCampus = _history.where((l) => l.locationStatus == 'On-Campus').length;
    final offCampus = _history.where((l) => l.locationStatus != 'On-Campus' && l.regularisationStatus != 'Regularised').length;
    final regularised = _history.where((l) => l.regularisationStatus == 'Regularised').length;

    final chips = [
      {'label': 'Total', 'count': total, 'color': _accent, 'icon': Icons.list_alt_rounded},
      {'label': 'On-Campus', 'count': onCampus, 'color': _success, 'icon': Icons.check_circle_rounded},
      {'label': 'Off-Campus', 'count': offCampus, 'color': _danger, 'icon': Icons.warning_rounded},
      {'label': 'Regularised', 'count': regularised, 'color': _warning, 'icon': Icons.info_rounded},
    ];

    return isMobile
        ? GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: chips.map((c) => _summaryChip(
                c['label'] as String, c['count'] as int,
                c['color'] as Color, c['icon'] as IconData)).toList(),
          )
        : Row(
            children: chips.asMap().entries.map((e) {
              return Expanded(
                child: Padding(
                  padding: e.key < chips.length - 1
                      ? const EdgeInsets.only(right: 12)
                      : EdgeInsets.zero,
                  child: _summaryChip(
                      e.value['label'] as String,
                      e.value['count'] as int,
                      e.value['color'] as Color,
                      e.value['icon'] as IconData),
                ),
              );
            }).toList(),
          );
  }

  Widget _summaryChip(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.1 : 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(count.toString(),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5)),
              Text(label,
                  style: TextStyle(fontSize: 11, color: _textSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Legend ─────────────────────────────────────────────────────────────────
  Widget _buildLegend(bool isMobile) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _legendItem('On-Campus', _success, Icons.check_circle_rounded),
        _legendItem('Off-Campus', _danger, Icons.warning_rounded),
        _legendItem('Regularised', _warning, Icons.info_rounded),
      ],
    );
  }

  Widget _legendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: color, size: 12),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: _textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ── Log card ───────────────────────────────────────────────────────────────
  Widget _buildLogCard(AttendanceLog log, bool isMobile) {
    final bgColor     = _cardBgColor(log);
    final borderColor = _cardBorderColor(log);
    final accentColor = _cardAccentColor(log);
    final locIcon     = _locationIcon(log);
    final isRegularised = log.regularisationStatus == 'Regularised';

    return InkWell(
      onTap: () => _showRegularisationDialog(log),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(_isDarkMode ? 0.08 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Top section: date + status badge ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.calendar_today_rounded,
                            color: accentColor, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        log.formattedDate,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 14 : 15,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (isRegularised)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _warning.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_rounded, color: _warning, size: 12),
                              const SizedBox(width: 4),
                              Text('Regularised',
                                  style: TextStyle(
                                      color: _warning,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      // Tap hint
                      Icon(Icons.touch_app_rounded, size: 16, color: accentColor.withOpacity(0.5)),
                    ],
                  ),
                ],
              ),
            ),

            // ── Divider ──────────────────────────────────────────────────
            Divider(height: 1, color: borderColor),

            // ── Clock times ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: isMobile
                  ? Column(
                      children: [
                        _timeRow(Icons.login_rounded, 'Clock-in', log.formattedClockInTime, _success),
                        const SizedBox(height: 8),
                        _timeRow(Icons.logout_rounded, 'Clock-out', log.formattedClockOutTime, _danger),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _timeRow(Icons.login_rounded, 'Clock-in', log.formattedClockInTime, _success)),
                        Container(width: 1, height: 32, color: borderColor),
                        Expanded(child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: _timeRow(Icons.logout_rounded, 'Clock-out', log.formattedClockOutTime, _danger),
                        )),
                      ],
                    ),
            ),

            // ── Divider ──────────────────────────────────────────────────
            Divider(height: 1, color: borderColor),

            // ── Bottom section: location + duration ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Location detail
                  Expanded(
                    child: Row(
                      children: [
                        Icon(locIcon, color: accentColor, size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            log.locationDetail ?? 'N/A',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Duration badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, color: accentColor, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          log.formattedDuration,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: accentColor,
                          ),
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
    );
  }

  Widget _timeRow(IconData icon, String label, String time, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 13),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: _textSecondary, fontWeight: FontWeight.w500)),
            Text(time, style: TextStyle(fontSize: 13, color: _textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
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
            decoration: BoxDecoration(color: _accent.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(Icons.history_rounded, size: 48, color: _accent.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text('No Records Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary)),
          const SizedBox(height: 8),
          Text('Your attendance history will appear here.',
              style: TextStyle(fontSize: 14, color: _textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchAttendanceHistory,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────
  Widget _buildErrorState(double padding) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: _danger.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.error_outline_rounded, size: 48, color: _danger.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),
            Text('Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary)),
            const SizedBox(height: 8),
            Text(_errorMessage!,
                style: TextStyle(fontSize: 13, color: _textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchAttendanceHistory,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}