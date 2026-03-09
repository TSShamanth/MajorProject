import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/services/api_service.dart';
import '../providers/institution_provider.dart';

class AppLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final List<Map<String, dynamic>> menuItems;
  final List<Widget>? breadcrumbs;
  final String userRole;
  final String userDisplayName;
  final String userSubTitle;
  final String avatarText;
  final String? institutionId;

  const AppLayout({
    super.key,
    required this.child,
    this.title = 'Dashboard',
    required this.menuItems,
    this.breadcrumbs,
    required this.userRole,
    required this.userDisplayName,
    required this.userSubTitle,
    required this.avatarText,
    this.institutionId,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  bool _sidebarExpanded = true;
  bool _isDarkMode = false;
  String? _institutionId;
  int _notificationCount = 0;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _institutionId = widget.institutionId;
    if (_institutionId == null) {
      _fetchInstitutionId();
    }
    _fetchNotificationCount();
  }

  Future<void> _fetchInstitutionId() async {
    final id = await SessionManager.getInstitutionId();
    debugPrint('AppLayout: Fetched institutionId from session: $id');
    if (mounted) {
      setState(() {
        _institutionId = id;
      });
      
      // Trigger provider fetch if not loaded
      final provider = Provider.of<InstitutionProvider>(context, listen: false);
      if (provider.institution == null && id != null) {
        debugPrint('AppLayout: Triggering provider fetch for $id');
        provider.fetchInstitutionProfile(id);
      }
    }
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final list = await _apiService.getNotifications();
      if (mounted) {
        setState(() {
          _notificationCount = list.where((n) => !n.read).length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Color get _bgColor => _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
  Color get _cardColor => _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
  Color get _textPrimary => _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
  Color get _textSecondary => _isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get _borderColor => _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Consumer<InstitutionProvider>(
      builder: (context, provider, _) {
        final primaryColor = provider.primaryColor;
        final logoUrl = provider.institution?.logoUrl;
        final institutionName = provider.institution?.name ?? 'Acadexa';

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 1024;

            return Scaffold(
              backgroundColor: _bgColor,
              drawer: isMobile ? _buildMobileDrawer(primaryColor, logoUrl, institutionName) : null,
              body: Row(
                children: [
                  if (!isMobile) _buildModernSidebar(primaryColor, logoUrl, institutionName),
                  Expanded(
                    child: Column(
                      children: [
                        _buildModernTopBar(isMobile: isMobile, primaryColor: primaryColor),
                        _buildBreadcrumb(),
                        Expanded(
                          child: widget.child,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMobileDrawer(Color primaryColor, String? logoUrl, String institutionName) {
    return Drawer(
      width: 270,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDarkMode 
                ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                : [primaryColor, primaryColor.withBlue(primaryColor.blue + 20).withRed(primaryColor.red - 20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _buildSidebarContent(primaryColor, logoUrl, institutionName, isMobile: true),
      ),
    );
  }

  Widget _buildModernSidebar(Color primaryColor, String? logoUrl, String institutionName) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _sidebarExpanded ? 270 : 0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode 
              ? [const Color(0xFF1F2937), const Color(0xFF111827)]
              : [primaryColor, primaryColor.withBlue(primaryColor.blue + 20).withRed(primaryColor.red - 20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: _sidebarExpanded ? [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.15),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ] : [],
      ),
      child: _sidebarExpanded ? _buildSidebarContent(primaryColor, logoUrl, institutionName) : const SizedBox.shrink(),
    );
  }

  Widget _buildSidebarContent(Color primaryColor, String? logoUrl, String institutionName, {bool isMobile = false}) {
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(_isDarkMode ? 0.05 : 0.1),
                width: 1,
              ),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: logoUrl != null && logoUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildLogoFallback(primaryColor, institutionName)),
                      )
                    : _buildLogoFallback(primaryColor, institutionName),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  institutionName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isMobile)
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                  onPressed: () => setState(() => _sidebarExpanded = false),
                )
              else
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: widget.menuItems.map((item) {
              final route = item['route'] as String?;
              final bool isActive = route != null && (currentPath == route || currentPath.startsWith('$route/'));
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (isMobile) Navigator.pop(context);
                      if (route != null && _institutionId != null) {
                        final fullRoute = route.startsWith('/') ? '/$_institutionId$route' : '/$_institutionId/$route';
                        context.go(fullRoute);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isActive 
                            ? Colors.white.withOpacity(_isDarkMode ? 0.1 : 0.15) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isActive 
                            ? Border.all(
                                color: Colors.white.withOpacity(_isDarkMode ? 0.2 : 0.3),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: Colors.white.withOpacity(isActive ? 1.0 : 0.7),
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              item['label'] as String,
                              style: TextStyle(
                                color: Colors.white.withOpacity(isActive ? 1.0 : 0.8),
                                fontSize: 15,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(_isDarkMode ? 0.05 : 0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSidebarFooterItem(Icons.help_outline_rounded, 'Help & Support'),
              const SizedBox(height: 4),
              _buildSidebarFooterItem(Icons.description_outlined, 'Documentation'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoFallback(Color primaryColor, String institutionName) {
    return Text(
      institutionName.isNotEmpty ? institutionName[0].toUpperCase() : 'A',
      style: TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w900,
        fontSize: 22,
      ),
    );
  }

  Widget _buildSidebarFooterItem(IconData icon, String label) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white.withOpacity(0.6)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTopBar({bool isMobile = false, required Color primaryColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: Icon(Icons.menu_rounded, color: _textPrimary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            )
          else if (!_sidebarExpanded)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF1F2937) : primaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (_isDarkMode ? const Color(0xFF1F2937) : primaryColor).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => setState(() => _sidebarExpanded = true),
              ),
            ),
          
          if (!isMobile) ...[
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
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
                          hintText: 'Search...',
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
          ],

          const SizedBox(width: 20),
          
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: _isDarkMode ? const Color(0xFFFBBF24) : primaryColor,
            ),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),

          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_rounded, color: _textPrimary),
                onPressed: () {
                  if (_institutionId != null) {
                    context.push('/$_institutionId/notifications');
                  }
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      '$_notificationCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),
          
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.only(left: 20),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: _borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [primaryColor, primaryColor.withBlue(primaryColor.blue + 30)]),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(widget.avatarText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.userDisplayName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textPrimary)),
                      Text(widget.userSubTitle, style: TextStyle(fontSize: 12, color: _textSecondary)),
                    ],
                  ),
                  PopupMenuButton(
                    icon: Icon(Icons.arrow_drop_down, color: _textSecondary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                            const SizedBox(width: 10),
                            const Text('Logout', style: TextStyle(color: Colors.red)),
                          ],
                        ),
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
              if (_institutionId != null) context.go('/$_institutionId/${widget.userRole.toLowerCase()}/dashboard');
            },
            child: Text('Home', style: TextStyle(color: _textSecondary, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, size: 16, color: _textSecondary),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              if (_institutionId != null) context.go('/$_institutionId/${widget.userRole.toLowerCase()}/dashboard');
            },
            child: Text('Dashboard', style: TextStyle(color: _textSecondary, fontSize: 13)),
          ),
          if (widget.breadcrumbs != null) ...widget.breadcrumbs!,
        ],
      ),
    );
  }
}
