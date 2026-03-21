import 'package:flutter/material.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/models/user_model.dart';
import 'app_layout.dart';

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
  UserModel? _user;
  bool _isLoading = true;
  String? _institutionId;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final instId = await SessionManager.getInstitutionId();
      if (instId == null) return;
      
      final apiService = ApiService();
      final user = await apiService.getMe(instId);
      
      if (mounted) {
        setState(() {
          _user = user;
          _institutionId = instId;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('AdminLayout: Error fetching user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = _user?.role ?? 'admin';
    
    final allMenuItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'route': '/admin/dashboard', 'roles': ['admin', 'hr_admin', 'finance_admin', 'exam_admin', 'admission_admin']},
      {'icon': Icons.people_rounded, 'label': 'User Management', 'route': '/admin/user-management', 'roles': ['admin', 'hr_admin', 'admission_admin']},
      {'icon': Icons.supervisor_account_rounded, 'label': 'Mentor Management', 'route': '/admin/mentor-management', 'roles': ['admin', 'hr_admin', 'admission_admin']},
      {'icon': Icons.settings_applications_rounded, 'label': 'Institution Setup', 'route': '/admin/institution-settings', 'roles': ['admin']},
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Fee Management', 'route': '/admin/fee-management', 'roles': ['admin', 'finance_admin']},
      {'icon': Icons.timer_rounded, 'label': 'Time Slots', 'route': '/admin/timetable/timeslots', 'roles': ['admin', 'admission_admin']},
      {'icon': Icons.calendar_today_rounded, 'label': 'Working Days', 'route': '/admin/timetable/working-days', 'roles': ['admin', 'admission_admin']},
      {'icon': Icons.grid_on_rounded, 'label': 'Timetable', 'route': '/admin/timetable/generate', 'roles': ['admin', 'admission_admin']},
      {'icon': Icons.school_rounded, 'label': 'Examinations', 'route': '/admin/exam-dashboard', 'roles': ['admin', 'exam_admin']},
      {'icon': Icons.inventory_2_rounded, 'label': 'Inventory', 'route': '/admin/inventory', 'roles': ['admin']},
      {'icon': Icons.build_rounded, 'label': 'Form Builder', 'route': '/admin/form-builder', 'roles': ['admin']},
      {'icon': Icons.approval, 'label': 'Approval', 'route': '/admin/approval', 'roles': ['admin', 'hr_admin']},
      {'icon': Icons.event_rounded, 'label': 'Event Management', 'route': '/events', 'roles': ['admin', 'hr_admin']},
      {'icon': Icons.announcement_rounded, 'label': 'Announcements', 'route': '/announcements/manage', 'roles': ['admin', 'hr_admin']},
      {'icon': Icons.groups_rounded, 'label': 'Alumni Network', 'route': '/admin/alumni-dashboard', 'roles': ['admin', 'hr_admin']},
    ];

    final filteredMenu = allMenuItems.where((item) {
      final allowedRoles = item['roles'] as List<String>;
      return allowedRoles.contains(role);
    }).toList();

    String roleLabel = role.replaceAll('_', ' ').toUpperCase();
    String avatarText = _user?.displayName != null && _user!.displayName.isNotEmpty 
        ? _user!.displayName.substring(0, 1).toUpperCase() 
        : 'AD';

    return AppLayout(
      title: widget.title,
      menuItems: filteredMenu,
      breadcrumbs: widget.breadcrumbs,
      userRole: 'admin',
      userDisplayName: _user?.displayName ?? 'Admin',
      userSubTitle: roleLabel,
      avatarText: avatarText,
      institutionId: _institutionId,
      child: widget.child,
    );
  }
}
