import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/announcement_service.dart'; 
import '../models/announcement_model.dart';
import '../models/user_model.dart';
import '../widgets/create_user_dialog.dart';
import '../widgets/admin_layout.dart';
import '../providers/institution_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  String? _institutionId;
  int _studentCount = 0;
  int _facultyCount = 0;
  int _adminCount = 0;
  late AnimationController _animationController;

  final ApiService _apiService = ApiService();
  final AnnouncementService _announcementService = AnnouncementService(); 

  // Announcement state variables
  List<AnnouncementModel> _myAnnouncements = [];
  List<AnnouncementModel> _allAnnouncements = [];
  List<AnnouncementModel> _audienceAnnouncements = [];
  bool _isLoadingAnnouncements = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fetchInstitutionId().then((_) {
      if (_institutionId != null) {
        _fetchUsersAndCounts();
        _fetchCurrentUserAndAnnouncements(); 
      }
    });
  }

  Future<void> _fetchInstitutionId() async {
    final institutionId = await SessionManager.getInstitutionId();
    setState(() {
      _institutionId = institutionId;
    });
  }

  Future<void> _fetchCurrentUserAndAnnouncements() async {
    if (_institutionId == null) return;
    try {
      final user = await _apiService.getMe(_institutionId!);
      setState(() {
        _currentUser = user;
      });
      await _fetchAnnouncements();
    } catch (e) {
      debugPrint('Error fetching current user profile: $e');
    }
  }

  Future<void> _fetchAnnouncements() async {
    if (_institutionId == null) return;
    setState(() {
      _isLoadingAnnouncements = true;
    });

    try {
      final myAnnouncements = await _announcementService.getMyAnnouncementsFromBackend(_institutionId!);
      final allAnnouncements = await _announcementService.getAllAnnouncements(_institutionId!);
      final audienceAnnouncements = await _announcementService.getAnnouncements(
        _institutionId!,
        role: _currentUser?.role,
        departmentId: _currentUser?.departmentId,
        programme: _currentUser?.programme,
      );

      setState(() {
        _myAnnouncements = myAnnouncements;
        _allAnnouncements = allAnnouncements;
        _audienceAnnouncements = audienceAnnouncements;
        _isLoadingAnnouncements = false;
      });
    } catch (e) {
      debugPrint('Error fetching announcements: $e');
      setState(() {
        _isLoadingAnnouncements = false;
      });
    }
  }

  Future<void> _fetchUsersAndCounts() async {
    if (_institutionId == null) return;
    try {
      final users = await _apiService.getUsers(_institutionId!);
      int studentCount = 0;
      int facultyCount = 0;
      int adminCount = 0;
      for (var user in users) {
        if (user.role == 'student') {
          studentCount++;
        } else if (user.role == 'faculty') {
          facultyCount++;
        } else if (user.role == 'admin') {
          adminCount++;
        }
      }
      setState(() {
        _studentCount = studentCount;
        _facultyCount = facultyCount;
        _adminCount = adminCount;
      });
    } catch (e) {
      debugPrint('Error fetching users and counts: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _hasRole(List<String> roles) {
    if (_currentUser == null || _currentUser!.role == null) return false;
    final userRole = _currentUser!.role!.toLowerCase().trim().replaceAll(' ', '_');
    return roles.contains(userRole);
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateUserDialog(
        onSuccess: _fetchUsersAndCounts,
      ),
    );
  }

  // Helper for reactive colors
  Color get _primaryColor => Provider.of<InstitutionProvider>(context, listen: false).primaryColor;
  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get _bgColor => _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
  Color get _cardColor => _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
  Color get _textPrimary => _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
  Color get _textSecondary => _isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get _borderColor => _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Admin Dashboard',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;
          final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
          final isDesktop = constraints.maxWidth >= 1024;

          return _buildDashboardContent(
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
          );
        },
      ),
    );
  }

  Widget _buildDashboardContent({
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final padding = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Overview',
              style: TextStyle(
                fontSize: isMobile ? 22 : (isTablet ? 24 : 26),
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete academic workforce and placement management',
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: _textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            SizedBox(height: isMobile ? 16 : 24),

            _buildResponsiveStatsRow(isMobile, isTablet),
            SizedBox(height: isMobile ? 16 : 20),

            _buildAnnouncementsSection(isMobile, isTablet),
            SizedBox(height: isMobile ? 16 : 20),

            _buildResponsiveMainContent(isMobile, isTablet, isDesktop),
            SizedBox(height: isMobile ? 16 : 20),

            _buildResponsiveManagementSection(isMobile, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveStatsRow(bool isMobile, bool isTablet) {
    if (isMobile) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = (constraints.maxWidth / 180).floor().clamp(1, 2);
          
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: [
              _buildStatCard('Active Students', _studentCount.toString(), 'Current Enrolled', Icons.people_rounded, _primaryColor),
              _buildStatCard('Faculty', _facultyCount.toString(), 'All Departments', Icons.school_rounded, const Color(0xFF10B981)),
              _buildStatCard('Placement', '82%', 'Current Season', Icons.business_center_rounded, const Color(0xFF8B5CF6)),
              _buildStatCard('Actions', '12', '8 Pending', Icons.warning_rounded, const Color(0xFFF59E0B)),
            ],
          );
        },
      );
    } else if (isTablet) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _buildStatCard('Active Students', _studentCount.toString(), 'Current Enrolled', Icons.people_rounded, _primaryColor),
          _buildStatCard('Faculty', _facultyCount.toString(), 'All Departments', Icons.school_rounded, const Color(0xFF10B981)),
          _buildStatCard('Placement', '82%', 'Current Season', Icons.business_center_rounded, const Color(0xFF8B5CF6)),
          _buildStatCard('Actions', '12', '8 Pending', Icons.warning_rounded, const Color(0xFFF59E0B)),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(child: _buildStatCard('Active Students', _studentCount.toString(), 'Current Enrolled', Icons.people_rounded, _primaryColor)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('Faculty', _facultyCount.toString(), 'All Departments', Icons.school_rounded, const Color(0xFF10B981))),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('Placement', '82%', 'Current Season', Icons.business_center_rounded, const Color(0xFF8B5CF6))),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('Actions', '12', '8 Pending', Icons.warning_rounded, const Color(0xFFF59E0B))),
        ],
      );
    }
  }

  Widget _buildResponsiveMainContent(bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile || isTablet) {
      return Column(
        children: [
          _buildUserManagementCard(),
          const SizedBox(height: 16),
          _buildQuickActionsCard(),
          const SizedBox(height: 16),
          _buildSystemOverviewCard(),
          const SizedBox(height: 16),
          _buildRecentActivityCard(),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildUserManagementCard(),
                const SizedBox(height: 16),
                _buildRecentActivityCard(),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildQuickActionsCard(),
                const SizedBox(height: 16),
                _buildSystemOverviewCard(),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildResponsiveManagementSection(bool isMobile, bool isTablet) {
    if (isMobile) {
      return Column(
        children: [
          _buildAcademicsCard(),
          const SizedBox(height: 12),
          _buildFinancialsCard(),
          const SizedBox(height: 12),
          _buildResourcesCard(),
          const SizedBox(height: 12),
          _buildToolsCard(),
          const SizedBox(height: 12),
          _buildCommunityCard(),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAcademicsCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildFinancialsCard()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildResourcesCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildToolsCard()),
            ],
          ),
          const SizedBox(height: 16),
          _buildCommunityCard(),
        ],
      );
    }
  }

  Widget _buildStatCard(String title, String value, String subtext, IconData icon, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        return Container(
          padding: EdgeInsets.all(isMobile ? 14 : 20),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDarkMode ? 0.1 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: isMobile ? 20 : 22),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 30,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 13,
                  color: _textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                style: TextStyle(
                  fontSize: isMobile ? 10 : 12,
                  color: _textSecondary.withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserManagementCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.1 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.people_rounded, color: _primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'User Management',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              if (_hasRole(['admin', 'hr_admin', 'admission_admin']))
                ElevatedButton.icon(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add User', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildUserTypeTile('Students', _studentCount.toString(), 'Active accounts', _primaryColor, Icons.school_rounded, onTap: () {
            if (_institutionId != null) {
              context.go('/$_institutionId/admin/users/student');
            }
          }),
          const SizedBox(height: 10),
          _buildUserTypeTile('Faculty', _facultyCount.toString(), 'Active accounts', const Color(0xFF10B981), Icons.people_rounded, onTap: () {
            if (_institutionId != null) {
              context.go('/$_institutionId/admin/users/faculty');
            }
          }),
          const SizedBox(height: 10),
          _buildUserTypeTile('Admins', _adminCount.toString(), 'System administrators', const Color(0xFF8B5CF6), Icons.admin_panel_settings_rounded, onTap: () {
            if (_institutionId != null) {
              context.go('/$_institutionId/admin/users/admin');
            }
          }),
        ],
      ),
    );
  }

  Widget _buildUserTypeTile(String title, String count, String subtitle, Color color, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(_isDarkMode ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(_isDarkMode ? 0.3 : 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(_isDarkMode ? 0.25 : 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  count,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    final activities = [
      {'title': 'New Company Registration - Wipro', 'time': '1 hour ago', 'icon': Icons.info_rounded, 'color': _primaryColor},
      {'title': 'Semester Results Published', 'time': '3 hours ago', 'icon': Icons.check_circle_rounded, 'color': const Color(0xFF10B981)},
      {'title': 'Faculty Leave Approval', 'time': '5 pending', 'icon': Icons.access_time_rounded, 'color': const Color(0xFFF59E0B)},
      {'title': 'Placement Drive - Microsoft', 'time': 'Jan 18', 'icon': Icons.event_rounded, 'color': const Color(0xFF8B5CF6)},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.1 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.filter_list_rounded, size: 18, color: _textSecondary),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...activities.map((activity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: activity['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activity['time'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      activity['icon'] as IconData,
                      size: 16,
                      color: activity['color'] as Color,
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

  Widget _buildQuickActionsCard() {
    final allActions = [
      {'label': 'Manage Users', 'color': _primaryColor, 'icon': Icons.people_rounded, 'route': 'manage_users', 'roles': ['admin', 'hr_admin', 'admission_admin']},
      {'label': 'Mentor Management', 'color': const Color(0xFFEC4899), 'icon': Icons.supervisor_account_rounded, 'route': '/admin/mentor-management', 'roles': ['admin', 'hr_admin', 'admission_admin']},
      {'label': 'System Reports', 'color': const Color(0xFF8B5CF6), 'icon': Icons.bar_chart_rounded, 'route': null, 'roles': ['admin']},
    ];

    final actions = allActions.where((a) => (a['roles'] as List<String>).contains(_currentUser?.role ?? '')).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.1 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return InkWell(
                onTap: () async {
                  if (action['route'] == 'manage_users') {
                    _showAddUserDialog();
                  } else if (action['route'] != null) {
                    final route = action['route'] as String;
                    if (_institutionId != null) {
                      context.go(route);
                    }
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withOpacity(_isDarkMode ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          action['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: action['color'] as Color,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSystemOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, const Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Overview',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildOverviewItem('₹6.8L', 'Avg Package'),
              _buildOverviewItem('45', 'Recruiters'),
              _buildOverviewItem('1,248', 'Applications'),
              _buildOverviewItem('342', 'Active Users'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicsCard() {
    return _buildManagementCard(
      'Academics',
      const Color(0xFF10B981),
      Icons.school_rounded,
      [
        {'title': 'Class Management', 'route': '/$_institutionId/admin/class-management', 'roles': ['admin', 'admission_admin']},
        {'title': 'Examinations', 'route': '/$_institutionId/admin/exam-management', 'roles': ['admin', 'exam_admin']},
        {'title': 'Report Cards', 'route': '/$_institutionId/admin/report-card-dashboard', 'roles': ['admin', 'exam_admin']},
      ],
    );
  }

  Widget _buildFinancialsCard() {
    return _buildManagementCard(
      'Financials',
      const Color(0xFFF59E0B),
      Icons.monetization_on_rounded,
      [
        {'title': 'Fee Management', 'route': '/$_institutionId/admin/fee-management', 'roles': ['admin', 'finance_admin']},
      ],
    );
  }

  Widget _buildResourcesCard() {
    return _buildManagementCard(
      'Resources',
      const Color(0xFF8B5CF6),
      Icons.inventory_2_rounded,
      [
        {'title': 'Inventory', 'route': '/$_institutionId/admin/inventory', 'roles': ['admin']},
        {'title': 'Room Management', 'route': '/$_institutionId/admin/room-management', 'roles': ['admin', 'exam_admin']},
      ],
    );
  }

  Widget _buildToolsCard() {
    return _buildManagementCard(
      'Tools',
      const Color(0xFF14B8A6),
      Icons.build_rounded,
      [
        {'title': 'Form Builder', 'route': '/$_institutionId/admin/form-builder', 'roles': ['admin']},
      ],
    );
  }

  Widget _buildCommunityCard() {
    return _buildManagementCard(
      'Community',
      _primaryColor,
      Icons.groups_rounded,
      [
        {'title': 'Alumni Network', 'route': '/$_institutionId/admin/alumni-dashboard', 'roles': ['admin', 'hr_admin']},
      ],
    );
  }

  Widget _buildManagementCard(String title, Color color, IconData icon, List<Map<String, dynamic>> allItems) {
    final items = allItems.where((item) {
      final allowedRoles = item['roles'] as List<String>;
      return allowedRoles.contains(_currentUser?.role ?? 'admin');
    }).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.1 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  final route = item['route'] as String?;
                  if (route != null && _institutionId != null) {
                    context.go(route);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(_isDarkMode ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(_isDarkMode ? 0.3 : 0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: color,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection(bool isMobile, bool isTablet) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.1 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.announcement_rounded, color: _primaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Announcements',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      if (_institutionId != null) {
                        context.go('/$_institutionId/announcements/manage');
                      }
                    },
                    icon: const Icon(Icons.settings_rounded, size: 16),
                    label: const Text('Manage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(foregroundColor: _primaryColor),
                  ),
                ],
              ),
            ),
            TabBar(
              labelColor: _primaryColor,
              unselectedLabelColor: _textSecondary,
              indicatorColor: _primaryColor,
              dividerColor: _borderColor,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'My Feed'),
                Tab(text: 'My Announcements'),
                Tab(text: 'All Announcements'),
              ],
            ),
            SizedBox(
              height: 350,
              child: TabBarView(
                children: [
                  _buildAnnouncementTabList(_audienceAnnouncements, 'No relevant announcements found.'),
                  _buildAnnouncementTabList(_myAnnouncements, 'You haven\'t created any announcements yet.'),
                  _buildAnnouncementTabList(_allAnnouncements, 'No announcements found.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementTabList(List<AnnouncementModel> announcements, String emptyMessage) {
    if (_isLoadingAnnouncements) {
      return const Center(child: CircularProgressIndicator());
    }

    if (announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.announcement_outlined, size: 40, color: _textSecondary.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: announcements.length,
      separatorBuilder: (context, index) => Divider(color: _borderColor.withOpacity(0.5)),
      itemBuilder: (context, index) {
        try {
          final announcement = announcements[index];
          return _buildAnnouncementItem(announcement);
        } catch (e) {
          debugPrint('Error building announcement item at index $index: $e');
          return ListTile(title: Text('Error loading item: $e', style: const TextStyle(fontSize: 10, color: Colors.red)));
        }
      },
    );
  }

  Widget _buildAnnouncementItem(AnnouncementModel announcement) {
    final dateStr = DateFormat('MMM dd, yyyy').format(announcement.createdAt);
    
    return InkWell(
      onTap: () {
        if (_institutionId != null) {
          context.push('/$_institutionId/announcements/${announcement.id}', extra: announcement);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (announcement.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.push_pin_rounded, size: 14, color: _primaryColor),
                  ),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 11, color: _textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              announcement.description,
              style: TextStyle(fontSize: 12, color: _textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildCategoryBadge(announcement.category ?? 'general'),
                const SizedBox(width: 8),
                Icon(Icons.visibility_outlined, size: 12, color: _textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${announcement.viewCount}',
                  style: TextStyle(fontSize: 11, color: _textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    Color color;
    switch (category.toLowerCase()) {
      case 'urgent': color = const Color(0xFFEF4444); break;
      case 'academic': color = const Color(0xFF3B82F6); break;
      case 'event': color = const Color(0xFF8B5CF6); break;
      default: color = const Color(0xFF10B981);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
