import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/services/auth_service.dart';

// Mock Data (unchanged)
class JobPosting {
  final String title;
  final String company;
  final String location;
  final String postedBy;

  JobPosting({
    required this.title,
    required this.company,
    required this.location,
    required this.postedBy,
  });
}

class AlumniJobBoardScreen extends StatefulWidget {
  const AlumniJobBoardScreen({super.key});

  @override
  State<AlumniJobBoardScreen> createState() => _AlumniJobBoardScreenState();
}

class _AlumniJobBoardScreenState extends State<AlumniJobBoardScreen> {
  // ── Mock Data (unchanged) ─────────────────────────────────────────────────
  final List<JobPosting> _jobs = [
    JobPosting(title: 'Senior Flutter Developer', company: 'Google', location: 'Bengaluru (Remote)', postedBy: 'Rohan Sharma \'20'),
    JobPosting(title: 'Data Analyst (Fresher)', company: 'Deloitte', location: 'Hyderabad', postedBy: 'Priya Singh \'21'),
    JobPosting(title: 'Mechanical Design Engineer', company: 'Tata Motors', location: 'Pune', postedBy: 'Amit Patel \'20'),
  ];

  // ── Shell state ────────────────────────────────────────────────────────────
  bool _sidebarExpanded = true;
  bool _isDarkMode = false;
  String? _institutionId;
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

  List<JobPosting> get _filteredJobs {
    if (_searchQuery.isEmpty) return _jobs;
    return _jobs.where((job) {
      return job.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.company.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.location.toLowerCase().contains(_searchQuery.toLowerCase());
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
          floatingActionButton: _buildFAB(),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SIDEBAR
  // ══════════════════════════════════════════════════════════════════════════
  List<Map<String, Object?>> _menuItems() => [
        {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'active': false, 'route': '/admin/alumni'},
        {'icon': Icons.group_outlined, 'label': 'Alumni Directory', 'active': false, 'route': '/admin/alumni-directory'},
        {'icon': Icons.work_outline, 'label': 'Job Board', 'active': true, 'route': null},
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
          const Text('Job Board',
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
                        hintText: 'Search jobs, companies, locations...',
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
            child: Text('Job Board',
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
          const Text('Job Board',
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
          const Text('Jobs',
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
    final filtered = _filteredJobs;

    return Column(
      children: [
        // Header bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: pad, vertical: 16),
          decoration: BoxDecoration(
            color: _cardColor,
            border: Border(bottom: BorderSide(color: _borderColor)),
          ),
          child: Row(
            children: [
              Icon(Icons.work_outline_rounded, color: _success, size: 20),
              const SizedBox(width: 8),
              Text(
                '${filtered.length} Job${filtered.length == 1 ? '' : 's'} Available',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
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
                    final job = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildJobCard(job),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Job card ───────────────────────────────────────────────────────────────
  Widget _buildJobCard(JobPosting job) {
    final companyInitial = job.company[0].toUpperCase();
    final companyColors = {
      'G': _success,
      'D': _accent,
      'T': _warning,
      'M': _purple,
    };
    final companyColor = companyColors[companyInitial] ?? _danger;

    return Container(
      padding: const EdgeInsets.all(18),
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
                  color: companyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(companyInitial,
                      style: TextStyle(
                          color: companyColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 20)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary)),
                    const SizedBox(height: 2),
                    Text(job.company,
                        style: TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                            fontWeight: FontWeight.w500)),
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
                child: const Icon(Icons.location_on_outlined,
                    size: 14, color: _accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(job.location,
                    style: TextStyle(
                        fontSize: 14,
                        color: _textPrimary,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        size: 14, color: _purple),
                  ),
                  const SizedBox(width: 8),
                  Text('Posted by ${job.postedBy}',
                      style: TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.visibility_rounded, size: 16),
              label: const Text('View Details',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        // TODO: Open a dialog or screen to post a new job
      },
      backgroundColor: _success,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Post Job',
          style: TextStyle(fontWeight: FontWeight.w700)),
      elevation: 4,
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
              color: _success.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.work_off_rounded,
                size: 48, color: _success.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text('No Jobs Found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary)),
          const SizedBox(height: 8),
          Text('Try adjusting your search',
              style: TextStyle(fontSize: 14, color: _textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _searchQuery = ''),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Clear Search',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _success,
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