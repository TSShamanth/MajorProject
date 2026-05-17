import 'package:flutter/material.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'app_layout.dart';

class FacultyLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final List<Widget>? breadcrumbs;

  const FacultyLayout({
    super.key,
    required this.child,
    this.title = 'Dashboard',
    this.breadcrumbs,
  });

  @override
  State<FacultyLayout> createState() => _FacultyLayoutState();
}

class _FacultyLayoutState extends State<FacultyLayout> {
  UserModel? _user;
  String? _institutionId;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final institutionId = GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'];
      if (institutionId != null) {
        final user = await _apiService.getMe(institutionId);
        if (mounted) {
          setState(() {
            _user = user;
            _institutionId = institutionId;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching faculty data for layout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'route': '/faculty/dashboard'},
      {'icon': Icons.person_outline_rounded, 'label': 'My Profile', 'route': '/faculty/profile'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Timetable', 'route': '/faculty/timetable'},
      {'icon': Icons.group_outlined, 'label': 'Mentees', 'route': '/faculty/mentees'},
      {'icon': Icons.payments_outlined, 'label': "Students' Fee Status", 'route': '/faculty/student-fees'},
      {'icon': Icons.description_outlined, 'label': 'Leave Application', 'route': '/faculty/leave'},
      {'icon': Icons.check_circle_outline, 'label': 'Approve Leaves', 'route': '/faculty/leave-approval'},
      {'icon': Icons.assignment_rounded, 'label': 'Course Assessments', 'route': '/faculty/assessments'},
      {'icon': Icons.grade_outlined, 'label': 'Marks Entry', 'route': '/faculty/marks-entry'},
      {'icon': Icons.attach_money_rounded, 'label': 'Payroll', 'route': '/faculty/payroll'},
      {'icon': Icons.assignment_turned_in_rounded, 'label': 'Mark Attendance', 'route': '/faculty/mark-attendance'},
      {'icon': Icons.history_outlined, 'label': 'Clock-in History', 'route': '/faculty/attendance-history'},
      {'icon': Icons.campaign_rounded, 'label': 'Announcements', 'route': '/announcements'},
      {'icon': Icons.event_available_rounded, 'label': 'Events', 'route': '/events'},
    ];

    return AppLayout(
      title: widget.title,
      menuItems: menuItems,
      breadcrumbs: widget.breadcrumbs,
      userRole: 'Faculty',
      userDisplayName: _user?.displayName ?? 'Faculty',
      userSubTitle: _user?.role?.toUpperCase() ?? 'FACULTY',
      avatarText: _user?.displayName != null && _user!.displayName.isNotEmpty ? _user!.displayName[0].toUpperCase() : 'F',
      institutionId: _institutionId,
      child: widget.child,
    );
  }
}
