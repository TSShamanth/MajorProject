import 'package:flutter/material.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'app_layout.dart';

class StudentLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final List<Widget>? breadcrumbs;

  const StudentLayout({
    super.key,
    required this.child,
    this.title = 'Dashboard',
    this.breadcrumbs,
  });

  @override
  State<StudentLayout> createState() => _StudentLayoutState();
}

class _StudentLayoutState extends State<StudentLayout> {
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
      debugPrint('Error fetching student data for layout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'route': '/student/dashboard'},
      {'icon': Icons.person_outline_rounded, 'label': 'My Profile', 'route': '/student/profile'},
      {'icon': Icons.supervisor_account_rounded, 'label': 'My Mentor', 'route': '/student/my-mentors'},
      {'icon': Icons.credit_card_rounded, 'label': 'Virtual ID', 'route': '/student/virtual-id'},
      {'icon': Icons.schedule_rounded, 'label': 'Timetable', 'route': '/student/timetable'},
      {'icon': Icons.article_outlined, 'label': 'My Hall Tickets', 'route': '/student/hall-tickets'},
      {'icon': Icons.menu_book_rounded, 'label': 'Academic Records', 'route': '/student/academics'},
      {'icon': Icons.assignment_rounded, 'label': 'Assignments & Tasks', 'route': '/student/academics'},
      {'icon': Icons.event_busy_rounded, 'label': 'Leave', 'route': '/student/leave'},
      {'icon': Icons.calendar_today_rounded, 'label': 'Events & Calendar', 'route': '/events'},
      {'icon': Icons.business_center_rounded, 'label': 'Placements', 'route': '/student/placement'},
      {'icon': Icons.campaign_rounded, 'label': 'Announcements', 'route': '/announcements'},
      {'icon': Icons.message_rounded, 'label': 'Messages', 'route': '/student/messages'},
      {'icon': Icons.payment_rounded, 'label': 'Fees', 'route': '/student/fees'},
      {'icon': Icons.edit_note_rounded, 'label': 'Study Planner', 'route': '/student/study-planner'},
      {'icon': Icons.notes_rounded, 'label': 'Notes', 'route': '/student/notes'},
      {'icon': Icons.description_outlined, 'label': 'Surveys & Forms', 'route': '/student/forms'}
    ];

    return AppLayout(
      title: widget.title,
      menuItems: menuItems,
      breadcrumbs: widget.breadcrumbs,
      userRole: 'Student',
      userDisplayName: _user?.displayName ?? 'Student',
      userSubTitle: _user?.programme ?? 'Undergraduate',
      avatarText: _user?.displayName != null && _user!.displayName.isNotEmpty ? _user!.displayName[0].toUpperCase() : 'S',
      institutionId: _institutionId,
      child: widget.child,
    );
  }
}
