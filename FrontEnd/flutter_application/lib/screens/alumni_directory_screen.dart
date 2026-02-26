import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/services/auth_service.dart';

// Mock Data (unchanged)
class Alumnus {
  final String name;
  final String program;
  final int graduationYear;
  final String company;
  final String role;

  Alumnus({
    required this.name,
    required this.program,
    required this.graduationYear,
    required this.company,
    required this.role,
  });
}

class AlumniDirectoryScreen extends StatefulWidget {
  const AlumniDirectoryScreen({super.key});

  @override
  State<AlumniDirectoryScreen> createState() => _AlumniDirectoryScreenState();
}

class _AlumniDirectoryScreenState extends State<AlumniDirectoryScreen> {
  // ── Mock Data (unchanged) ─────────────────────────────────────────────────
  final List<Alumnus> _alumni = [
    Alumnus(name: 'Rohan Sharma', program: 'B.Tech CSE', graduationYear: 2020, company: 'Google', role: 'Software Engineer'),
    Alumnus(name: 'Priya Singh', program: 'B.B.A.', graduationYear: 2021, company: 'Deloitte', role: 'Business Analyst'),
    Alumnus(name: 'Amit Patel', program: 'B.Tech Mech', graduationYear: 2020, company: 'Tata Motors', role: 'Mechanical Engineer'),
    Alumnus(name: 'Sunita Williams', program: 'B.Tech CSE', graduationYear: 2022, company: 'Microsoft', role: 'Product Manager'),
  ];

  // ── Shell state ────────────────────────────────────────────────────────────
  bool _sidebarExpanded = true;
  bool _isDarkMode = false;
  String? _institutionId;
  int? _selectedYear;
  String _searchQuery = '';

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
  static const _purple  = Color(0xFF8B5CF6);

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

  List<Alumnus> get _filteredAlumni {
    return _alumni.where((alumnus) {
      final matchesSearch = _searchQuery.isEmpty ||
          alumnus.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          alumnus.company.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesYear = _selectedYear == null || alumnus.graduationYear == _selectedYear;
      return matchesSearch && matchesYear;
    }).toList();
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
        {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'active': false, 'route': '/admin/alumni'},
        {'icon': Icons.group_outlined, 'label': 'Alumni Directory', 'active': true, 'route': null},
        {'icon': Icons.work_outline, 'label': 'Job Board', 'active': false, 'route': '/admin/alumni-job-board'},
        {'icon': Icons.event_outlined, 'label': 'Events', 'active': false, 'route': '/admin/alumni-events'},
        {'icon': Icons.favorite_border, 'label': 'Donations', 'active': false, 'route': '/admin/donations'},
        {'icon': Icons.analytics_outlined, 'label': 'Analytics', 'active': false, 'route': '/admin/analytics'},
        {'icon': Icons.settings_outlined, 'label': 'Settings', 'active': false, 'route': '/admin/settings'},
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
                        child: Text('AcadWorkHub',
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
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF4338CA)])),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('A', style: TextStyle(color: _accent, fontWeight: FontWeight.w900, fontSize: 22))),
                ),
                const SizedBox(width: 14),
                const Text('AcadWorkHub', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
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
          const Text('Alumni Directory',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _accent, letterSpacing: -0.3)),
          const SizedBox(width: 16),
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
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search by name, company...',
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
                child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: _danger, shape: BoxShape.circle)),
              ),
            ],
          ),
          const SizedBox(width: 20),
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
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: const Center(
                    child: Text('AD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Admin', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary)),
                    const SizedBox(height: 2),
                    Text('Alumni Portal', style: TextStyle(fontSize: 13, color: _textSecondary)),
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
            child: Text('Alumni Directory',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _accent),
                overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: _isDarkMode ? const Color(0xFFFBBF24) : _accent),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
        ],
      ),
    );
  }

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
          Text('Alumni Network', style: TextStyle(fontSize: 14, color: _textSecondary)),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right_rounded, size: 18, color: _textSecondary),
          const SizedBox(width: 10),
          const Text('Directory',
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
          Text('Alumni', style: TextStyle(fontSize: 12, color: _textSecondary)),
          Icon(Icons.chevron_right_rounded, size: 13, color: _textSecondary),
          const SizedBox(width: 4),
          const Text('Directory',
              style: TextStyle(fontSize: 12, color: _accent, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BODY
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBody({required bool isMobile}) {
    final pad = isMobile ? 16.0 : 28.0;
    final filtered = _filteredAlumni;

    return Column(
      children: [
        // Filter controls
        Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: _cardColor,
            border: Border(bottom: BorderSide(color: _borderColor)),
          ),
          child: _buildFilterControls(isMobile),
        ),
        // Results count
        Container(
          padding: EdgeInsets.symmetric(horizontal: pad, vertical: 12),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
            border: Border(bottom: BorderSide(color: _borderColor)),
          ),
          child: Row(
            children: [
              Icon(Icons.groups_rounded, color: _accent, size: 18),
              const SizedBox(width: 8),
              Text(
                '${filtered.length} ${filtered.length == 1 ? 'Alumnus' : 'Alumni'} Found',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              if (_selectedYear != null || _searchQuery.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _selectedYear = null;
                    _searchQuery = '';
                  }),
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  label: const Text('Clear Filters', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: _danger,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
        ),
        // List
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(pad),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final alumnus = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildAlumnusCard(alumnus),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Filter controls ────────────────────────────────────────────────────────
  Widget _buildFilterControls(bool isMobile) {
    return isMobile
        ? Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search by name, company...',
                    hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: _textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: TextStyle(color: _textPrimary, fontSize: 14),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    hint: Text('Filter by Year', style: TextStyle(color: _textSecondary, fontSize: 14)),
                    isExpanded: true,
                    dropdownColor: _cardColor,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: _textSecondary),
                    items: [2020, 2021, 2022]
                        .map((year) => DropdownMenuItem(
                              value: year,
                              child: Text(year.toString(), style: TextStyle(color: _textPrimary)),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedYear = value),
                  ),
                ),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor),
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search by name, company...',
                      hintStyle: TextStyle(color: _textSecondary, fontSize: 15),
                      prefixIcon: Icon(Icons.search_rounded, color: _textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: TextStyle(color: _textPrimary, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    hint: Text('Year', style: TextStyle(color: _textSecondary, fontSize: 15)),
                    dropdownColor: _cardColor,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: _textSecondary),
                    items: [2020, 2021, 2022]
                        .map((year) => DropdownMenuItem(
                              value: year,
                              child: Text(year.toString(), style: TextStyle(color: _textPrimary)),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedYear = value),
                  ),
                ),
              ),
            ],
          );
  }

  // ── Alumnus card ───────────────────────────────────────────────────────────
  Widget _buildAlumnusCard(Alumnus alumnus) {
    final initials = alumnus.name.split(' ').map((n) => n[0]).take(2).join().toUpperCase();
    final colors = [_accent, _success, _purple, _warning];
    final avatarColor = colors[alumnus.name.hashCode.abs() % colors.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(_isDarkMode ? 0.1 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [avatarColor, avatarColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alumnus.name,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      '${alumnus.program} • Class of ${alumnus.graduationYear}',
                      style: TextStyle(fontSize: 13, color: _textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: _borderColor, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.work_outline_rounded, size: 16, color: _accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${alumnus.role} at ${alumnus.company}',
                  style: TextStyle(fontSize: 14, color: _textPrimary, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_rounded, size: 16),
              label: const Text('View Profile',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
        ],
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
            child: Icon(Icons.search_off_rounded, size: 48, color: _accent.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text('No Alumni Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary)),
          const SizedBox(height: 8),
          Text('Try adjusting your search or filters',
              style: TextStyle(fontSize: 14, color: _textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {
              _selectedYear = null;
              _searchQuery = '';
            }),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Clear Filters', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
}