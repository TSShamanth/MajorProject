import 'package:flutter/material.dart';
import 'package:flutter_application/models/regularisation_request_dto.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';

class RegularisationRequestScreen extends StatefulWidget {
  const RegularisationRequestScreen({super.key});

  @override
  State<RegularisationRequestScreen> createState() =>
      _RegularisationRequestScreenState();
}

class _RegularisationRequestScreenState
    extends State<RegularisationRequestScreen> {
  // ── Form state ─────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _requestType;
  final TextEditingController _reasonController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

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

  static const _accent = Color(0xFF4F46E5);
  static const _success = Color(0xFF10B981);
  static const _danger = Color(0xFFEF4444);
  static const _warning = Color(0xFFF59E0B);

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

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_institutionId == null) throw Exception('Institution ID not found');

      final requestData = RegularisationRequestDTO(
        targetDate: _selectedDate!,
        targetTime:
            '${_selectedTime!.hour}:${_selectedTime!.minute}',
        type: _requestType!,
        reason: _reasonController.text,
        attendanceLogId: null,
      );

      await _apiService.createRegularisationRequest(
          _institutionId!, requestData.toJson());

      if (!mounted) return;
      _showSnackbar('Regularisation request submitted successfully!',
          isError: false);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Failed to submit request: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: isError ? _danger : _success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Date / time pickers ────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: _accent,
            onPrimary: Colors.white,
            surface: _cardColor,
            onSurface: _textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: _accent,
            onPrimary: Colors.white,
            surface: _cardColor,
            onSurface: _textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ── Input decoration ───────────────────────────────────────────────────────
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          TextStyle(fontSize: 14, color: _textSecondary),
      prefixIcon: Icon(icon, color: _accent, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _danger, width: 2),
      ),
      filled: true,
      fillColor: _bgColor,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
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
                          Expanded(child: _buildBody(isMobile: false)),
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
          'active': true,
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
                // Header
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
                                  : _accent,
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
                      Container(
                        decoration: BoxDecoration(
                          color:
                              Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(
                              Icons.chevron_left_rounded,
                              color: Colors.white,
                              size: 24),
                          onPressed: () => setState(
                              () => _sidebarExpanded = false),
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
                                            .withOpacity(
                                                isActive ? 1.0 : 0.8),
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
                      _sidebarFooterLink(
                          'Help & Support', Icons.help_outline_rounded),
                      const SizedBox(height: 4),
                      _sidebarFooterLink(
                          'Documentation', Icons.description_outlined),
                    ],
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _sidebarFooterLink(String label, IconData icon) {
    return InkWell(
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
  }

  // ── Mobile drawer ──────────────────────────────────────────────────────────
  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: _cardColor,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
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
  // TOP BAR (Desktop)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTopBar() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
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
          // Expand button (when sidebar is collapsed)
          if (!_sidebarExpanded)
            Container(
              margin: const EdgeInsets.only(right: 16),
              width: 46,
              height: 46,
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
                  onTap: () =>
                      setState(() => _sidebarExpanded = true),
                  borderRadius: BorderRadius.circular(12),
                  child: const Icon(Icons.menu_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
            ),

          // Page title
          const Text(
            'Regularisation Request',
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
                        hintText: 'Search attendance records...',
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

          // View status history button
          ElevatedButton.icon(
            onPressed: () {
              if (_institutionId != null) {
                context.push(
                    '/$_institutionId/faculty/regularisation/status');
              }
            },
            icon: const Icon(Icons.history_rounded, size: 18),
            label: const Text('View Status',
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
            width: 46,
            height: 46,
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
                width: 46,
                height: 46,
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
                right: 12,
                top: 12,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                      color: _danger, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),

          // User avatar + popup
          Container(
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
                border: Border(
                    left: BorderSide(color: _borderColor))),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4F46E5),
                        Color(0xFF7C3AED)
                      ],
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
                                fontSize: 15,
                                color: _textPrimary)),
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

  // ── Mobile top bar ─────────────────────────────────────────────────────────
  Widget _buildMobileTopBar() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              width: 40,
              height: 40,
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
              'Regularisation Request',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _accent,
              ),
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
          IconButton(
            icon: const Icon(Icons.history_rounded),
            color: _accent,
            onPressed: () {
              if (_institutionId != null) {
                context.push(
                    '/$_institutionId/faculty/regularisation/status');
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Breadcrumb (desktop) ───────────────────────────────────────────────────
  Widget _buildBreadcrumb() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          Text('Home',
              style:
                  TextStyle(fontSize: 14, color: _textSecondary)),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: _textSecondary),
          const SizedBox(width: 10),
          Text('Attendance History',
              style:
                  TextStyle(fontSize: 14, color: _textSecondary)),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: _textSecondary),
          const SizedBox(width: 10),
          const Text(
            'Regularisation Request',
            style: TextStyle(
              fontSize: 14,
              color: _accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile breadcrumb ──────────────────────────────────────────────────────
  Widget _buildMobileBreadcrumb() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          Icon(Icons.home_outlined, size: 14, color: _textSecondary),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded,
              size: 14, color: _textSecondary),
          const SizedBox(width: 6),
          Text('History',
              style:
                  TextStyle(fontSize: 12, color: _textSecondary)),
          Icon(Icons.chevron_right_rounded,
              size: 14, color: _textSecondary),
          const SizedBox(width: 6),
          const Text(
            'Regularisation',
            style: TextStyle(
                fontSize: 12,
                color: _accent,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BODY
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBody({required bool isMobile}) {
    final padding = isMobile ? 16.0 : 28.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Center(
        child: ConstrainedBox(
          // On desktop, cap the form width for readability
          constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page heading
              Text(
                'New Regularisation Request',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Submit a request to correct your clock-in or clock-out record',
                style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: _textSecondary),
              ),
              SizedBox(height: isMobile ? 20 : 28),

              // ── Form card ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                          _isDarkMode ? 0.1 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: const Icon(
                                Icons.edit_calendar_rounded,
                                color: _accent,
                                size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Request Details',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Section: Date & Time ─────────────────────────
                      _sectionLabel('Date & Time'),
                      const SizedBox(height: 12),

                      // Date + Time side by side on desktop, stacked on mobile
                      isMobile
                          ? Column(
                              children: [
                                _buildDateField(),
                                const SizedBox(height: 14),
                                _buildTimeField(),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: _buildDateField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTimeField()),
                              ],
                            ),
                      const SizedBox(height: 20),

                      // ── Section: Request Type ────────────────────────
                      _sectionLabel('Request Type'),
                      const SizedBox(height: 12),
                      _buildRequestTypeField(),
                      const SizedBox(height: 20),

                      // ── Section: Reason ──────────────────────────────
                      _sectionLabel('Reason'),
                      const SizedBox(height: 12),
                      _buildReasonField(),
                      const SizedBox(height: 28),

                      // ── Submit button ────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isLoading ? null : _submitRequest,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  size: 20),
                          label: Text(
                            _isLoading
                                ? 'Submitting...'
                                : 'Submit Request',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                _accent.withOpacity(0.6),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section label helper ───────────────────────────────────────────────────
  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  // ── Date field ─────────────────────────────────────────────────────────────
  Widget _buildDateField() {
    return TextFormField(
      decoration: _inputDecoration('Target Date', Icons.calendar_today_rounded),
      readOnly: true,
      style: TextStyle(
          fontSize: 15,
          color: _textPrimary,
          fontWeight: FontWeight.w500),
      onTap: _pickDate,
      controller: TextEditingController(
        text: _selectedDate == null
            ? ''
            : '${_selectedDate!.toLocal()}'.split(' ')[0],
      ),
      validator: (value) =>
          _selectedDate == null ? 'Please select a date' : null,
    );
  }

  // ── Time field ─────────────────────────────────────────────────────────────
  Widget _buildTimeField() {
    return TextFormField(
      decoration:
          _inputDecoration('Target Time', Icons.access_time_rounded),
      readOnly: true,
      style: TextStyle(
          fontSize: 15,
          color: _textPrimary,
          fontWeight: FontWeight.w500),
      onTap: _pickTime,
      controller: TextEditingController(
        text: _selectedTime == null
            ? ''
            : _selectedTime!.format(context),
      ),
      validator: (value) =>
          _selectedTime == null ? 'Please select a time' : null,
    );
  }

  // ── Request type dropdown ──────────────────────────────────────────────────
  Widget _buildRequestTypeField() {
    return DropdownButtonFormField<String>(
      decoration:
          _inputDecoration('Request Type', Icons.swap_horiz_rounded),
      dropdownColor: _cardColor,
      style: TextStyle(fontSize: 15, color: _textPrimary),
      value: _requestType,
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: _textSecondary),
      items: ['Clock-in', 'Clock-out'].map((type) {
        return DropdownMenuItem(
          value: type,
          child: Row(
            children: [
              Icon(
                type == 'Clock-in'
                    ? Icons.login_rounded
                    : Icons.logout_rounded,
                color: type == 'Clock-in' ? _success : _warning,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(type,
                  style: TextStyle(
                      fontSize: 15, color: _textPrimary)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _requestType = value),
      validator: (value) =>
          value == null ? 'Please select a request type' : null,
    );
  }

  // ── Reason field ───────────────────────────────────────────────────────────
  Widget _buildReasonField() {
    return TextFormField(
      controller: _reasonController,
      maxLines: 4,
      style: TextStyle(fontSize: 15, color: _textPrimary),
      decoration: _inputDecoration(
              'Reason for regularisation', Icons.notes_rounded)
          .copyWith(
        alignLabelWithHint: true,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 48, minHeight: 48),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a reason';
        }
        if (value.length < 10) {
          return 'Please provide a more detailed reason';
        }
        return null;
      },
    );
  }
}