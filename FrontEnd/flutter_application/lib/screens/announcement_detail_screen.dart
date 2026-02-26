import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';
import '../services/session_manager.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final AnnouncementModel announcement;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcement,
  });

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  // ── Business logic state (unchanged) ──────────────────────────────────────
  late AnnouncementService _announcementService;
  late ApiService _apiService;
  String? _institutionId;
  UserModel? _currentUser;
  late AnnouncementModel _announcement;
  bool _isLoading = false;
  bool _hasViewedMarked = false;

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

  static const _accent  = Color(0xFF4F46E5);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _danger  = Color(0xFFEF4444);
  static const _purple  = Color(0xFF8B5CF6);

  // ── Lifecycle (unchanged) ──────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _announcementService = AnnouncementService();
    _apiService = ApiService();
    _announcement = widget.announcement;
    _initializeData();
  }

  Future<void> _initializeData() async {
    final institutionId = await SessionManager.getInstitutionId();
    setState(() => _institutionId = institutionId);

    if (_institutionId != null) {
      _fetchCurrentUser();
      _markAsViewed();
      _fetchLatestAnnouncement();
    }
  }

  Future<void> _fetchCurrentUser() async {
    if (_institutionId == null) return;
    try {
      final user = await _apiService.getMe(_institutionId!);
      setState(() => _currentUser = user);
    } catch (e) {
      debugPrint('Error fetching current user: $e');
    }
  }

  Future<void> _fetchLatestAnnouncement() async {
    if (_institutionId == null) return;
    try {
      final announcement = await _announcementService.getAnnouncementById(
        _institutionId!,
        _announcement.id,
      );
      setState(() => _announcement = announcement);
    } catch (e) {
      debugPrint('Error fetching latest announcement: $e');
    }
  }

  Future<void> _markAsViewed() async {
    if (_institutionId == null || _hasViewedMarked) return;
    try {
      await _announcementService.markAnnouncementAsViewed(
        _institutionId!,
        _announcement.id,
      );
      setState(() => _hasViewedMarked = true);
    } catch (e) {
      debugPrint('Error marking as viewed: $e');
    }
  }

  Future<void> _editAnnouncement() async {
    if (_currentUser?.uid == _announcement.createdBy ||
        _currentUser?.role == 'admin') {
      context.push(
        '/$_institutionId/announcements/${_announcement.id}/edit',
        extra: _announcement,
      );
    } else {
      _showSnackbar('You can only edit your own announcements', isError: true);
    }
  }

  Future<void> _deleteAnnouncement() async {
    if (_currentUser?.uid != _announcement.createdBy &&
        _currentUser?.role != 'admin') {
      _showSnackbar('You can only delete your own announcements', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Announcement', style: TextStyle(color: _textPrimary)),
        content: Text('Are you sure you want to delete this announcement?',
            style: TextStyle(color: _textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: _danger, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && _institutionId != null) {
      setState(() => _isLoading = true);
      try {
        await _announcementService.deleteAnnouncement(
          _institutionId!,
          _announcement.id,
        );
        if (mounted) {
          _showSnackbar('Announcement deleted successfully', isError: false);
          context.pop();
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          _showSnackbar('Error deleting announcement: $e', isError: true);
        }
      }
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _downloadFile(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Could not open attachment: $e', isError: true);
      }
    }
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
        {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'active': false, 'route': '/faculty/dashboard'},
        {'icon': Icons.announcement_outlined, 'label': 'Announcements', 'active': true, 'route': null},
        {'icon': Icons.event_outlined, 'label': 'Events', 'active': false, 'route': '/events'},
        {'icon': Icons.settings_outlined, 'label': 'Settings', 'active': false, 'route': '/settings'},
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
    final canEdit = _currentUser?.uid == _announcement.createdBy ||
        _currentUser?.role == 'admin';

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
          // Back button
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: _textPrimary, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
          const Text('Announcement Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _accent, letterSpacing: -0.3)),
          const Spacer(),
          // Edit/Delete menu
          if (canEdit)
            Container(
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: PopupMenuButton(
                icon: Icon(Icons.more_vert_rounded, color: _textPrimary, size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                color: _cardColor,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: _editAnnouncement,
                    child: Row(children: [
                      Icon(Icons.edit_rounded, size: 18, color: _textPrimary),
                      const SizedBox(width: 12),
                      Text('Edit', style: TextStyle(fontSize: 14, color: _textPrimary)),
                    ]),
                  ),
                  PopupMenuItem(
                    onTap: _deleteAnnouncement,
                    child: const Row(children: [
                      Icon(Icons.delete_rounded, size: 18, color: _danger),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(fontSize: 14, color: _danger)),
                    ]),
                  ),
                ],
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
                  child: Center(
                    child: Text(
                      _currentUser?.displayName.isNotEmpty == true
                          ? _currentUser!.displayName.substring(0, 2).toUpperCase()
                          : 'U',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_currentUser?.displayName ?? 'User',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary)),
                    const SizedBox(height: 2),
                    Text(_currentUser?.role ?? 'User',
                        style: TextStyle(fontSize: 13, color: _textSecondary)),
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
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: _borderColor)),
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: _textPrimary, size: 18),
              onPressed: () => context.pop(),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Announcement',
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
          Text('Announcements', style: TextStyle(fontSize: 14, color: _textSecondary)),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right_rounded, size: 18, color: _textSecondary),
          const SizedBox(width: 10),
          const Text('Details',
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
          Text('Announcements', style: TextStyle(fontSize: 12, color: _textSecondary)),
          Icon(Icons.chevron_right_rounded, size: 13, color: _textSecondary),
          const SizedBox(width: 4),
          const Text('Details',
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

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _accent));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              _buildHeaderCard(),
              const SizedBox(height: 20),

              // Content card
              _buildContentCard(),
              const SizedBox(height: 20),

              // Target audience card
              _buildAudienceCard(),
              const SizedBox(height: 20),

              // Attachments card (if any)
              if (_announcement.attachmentUrls.isNotEmpty) ...[
                _buildAttachmentsCard(),
                const SizedBox(height: 20),
              ],

              // Metadata card
              _buildMetadataCard(),
            ],
          ),
        ),
      ),
    );
  }

  // Continue in next message due to length...
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          // Badges row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPriorityBadge(_announcement.priority),
              _buildCategoryChip(_announcement.category),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(_isDarkMode ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accent.withOpacity(_isDarkMode ? 0.3 : 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility_rounded, color: _accent, size: 14),
                    const SizedBox(width: 6),
                    Text('${_announcement.viewCount} views',
                        style: const TextStyle(
                            color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title
          Text(_announcement.title,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                  letterSpacing: -0.5)),
          const SizedBox(height: 16),

          // Author info
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_accent, _accent.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    _announcement.createdByName.isNotEmpty
                        ? _announcement.createdByName[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_announcement.createdByName,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatRole(_announcement.createdByRole)} • ${DateFormat('dd MMM yyyy, hh:mm a').format(_announcement.createdAt)}',
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description_rounded, color: _purple, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Description',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: _textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          Text(_announcement.description,
              style: TextStyle(
                  fontSize: 15, height: 1.6, color: _textPrimary)),

          if (_announcement.content != null && _announcement.content!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Divider(color: _borderColor),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.article_rounded, color: _success, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Detailed Content',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700, color: _textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: Text(_announcement.content!,
                  style: TextStyle(fontSize: 14, height: 1.6, color: _textPrimary)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAudienceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.groups_rounded, color: _warning, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Visible To',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: _textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _announcement.targetAudience
                .map((audience) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(_isDarkMode ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _accent.withOpacity(_isDarkMode ? 0.3 : 0.2)),
                      ),
                      child: Text(_formatRole(audience),
                          style: const TextStyle(
                              color: _accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.attach_file_rounded, color: _danger, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Attachments',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: _textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          ..._announcement.attachmentUrls.map((url) {
            final fileName = url.split('/').last.split('?').first;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.insert_drive_file_rounded,
                          color: _accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(fileName,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _textPrimary)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, color: _accent, size: 20),
                      onPressed: () => _downloadFile(url),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetadataCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Icon(Icons.calendar_today_rounded, color: _accent, size: 24),
                const SizedBox(height: 8),
                Text('Created',
                    style: TextStyle(fontSize: 12, color: _textSecondary)),
                const SizedBox(height: 4),
                Text(DateFormat('dd MMM yyyy').format(_announcement.createdAt),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _textPrimary)),
              ],
            ),
          ),
          Container(width: 1, height: 60, color: _borderColor),
          Expanded(
            child: Column(
              children: [
                Icon(Icons.update_rounded, color: _success, size: 24),
                const SizedBox(height: 8),
                Text('Updated',
                    style: TextStyle(fontSize: 12, color: _textSecondary)),
                const SizedBox(height: 4),
                Text(DateFormat('dd MMM yyyy').format(_announcement.updatedAt),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods (unchanged logic)
  Widget _buildPriorityBadge(int? priority) {
    late Color color;
    late String label;

    switch (priority) {
      case 1:
        color = _success;
        label = 'Low Priority';
        break;
      case 3:
        color = _danger;
        label = 'High Priority';
        break;
      default:
        color = _warning;
        label = 'Medium Priority';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(_isDarkMode ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(_isDarkMode ? 0.3 : 0.2)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildCategoryChip(String? category) {
    late Color color;
    late String label;

    switch (category) {
      case 'academic':
        color = _accent;
        label = 'Academic';
        break;
      case 'event':
        color = _purple;
        label = 'Event';
        break;
      case 'urgent':
        color = _danger;
        label = 'Urgent';
        break;
      default:
        color = _textSecondary;
        label = 'General';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(_isDarkMode ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(_isDarkMode ? 0.3 : 0.2)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  String _formatRole(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'faculty':
        return 'Faculty';
      case 'student':
        return 'Student';
      case 'alumni':
        return 'Alumni';
      default:
        return role.toUpperCase();
    }
  }
}