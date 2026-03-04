import 'package:flutter/material.dart';
import 'app_layout.dart';

class AdminLayout extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final menuItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'route': '/admin/dashboard'},
      {'icon': Icons.people_rounded, 'label': 'User Management', 'route': '/admin/user-management'},
      {'icon': Icons.supervisor_account_rounded, 'label': 'Mentor Management', 'route': '/admin/mentor-management'},
      {'icon': Icons.settings_applications_rounded, 'label': 'Institution Setup', 'route': '/admin/institution-settings'},
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Fee Management', 'route': '/admin/fee-management'},
      {'icon': Icons.timer_rounded, 'label': 'Time Slots', 'route': '/admin/timetable/timeslots'},
      {'icon': Icons.calendar_today_rounded, 'label': 'Working Days', 'route': '/admin/timetable/working-days'},
      {'icon': Icons.grid_on_rounded, 'label': 'Timetable', 'route': '/admin/timetable/generate'},
      {'icon': Icons.school_rounded, 'label': 'Examinations', 'route': '/admin/exam-dashboard'},
      {'icon': Icons.inventory_2_rounded, 'label': 'Inventory', 'route': '/admin/inventory'},
      {'icon': Icons.build_rounded, 'label': 'Form Builder', 'route': '/admin/form-builder'},
      {'icon': Icons.approval, 'label': 'Approval', 'route': '/admin/approval'},
      {'icon': Icons.event_rounded, 'label': 'Event Management', 'route': '/events'},
      {'icon': Icons.announcement_rounded, 'label': 'Announcements', 'route': '/announcements/manage'},
      {'icon': Icons.groups_rounded, 'label': 'Alumni Network', 'route': '/admin/alumni-dashboard'},
    ];

    // Wrap the path with institutionId in the router logic of AppLayout
    // but for the menu items we pass the relative paths which AppLayout will handle.
    // However, AppLayout expects full paths if we use context.go(route).
    // Let's ensure AppLayout handles the institutionId.
    
    return AppLayout(
      title: title,
      menuItems: menuItems.map((item) {
        return {
          ...item,
          'route': item['route'], // AppLayout will need to prepend institutionId
        };
      }).toList(),
      breadcrumbs: breadcrumbs,
      userRole: 'Admin',
      userDisplayName: 'Admin',
      userSubTitle: 'Administrator',
      avatarText: 'AD',
      child: child,
    );
  }
}
