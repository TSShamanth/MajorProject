import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class StudentShell extends StatelessWidget {
  final Widget child;

  const StudentShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {'icon': Icons.person_outline, 'label': 'Profile', 'description': 'View personal details'},
      {'icon': Icons.credit_card_outlined, 'label': 'Virtual ID', 'description': 'Access student ID card'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Timetable', 'description': 'View class schedule'},
      {'icon': Icons.menu_book_outlined, 'label': 'Academics', 'description': 'Semester & subjects'},
      {'icon': Icons.description_outlined, 'label': 'Leave', 'description': 'Apply & track leave'},
      {'icon': Icons.celebration_outlined, 'label': 'Events', 'description': 'Register for events'},
      {'icon': Icons.business_center_outlined, 'label': 'Placements', 'description': 'View opportunities'}
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Acadexa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                Text('Student Portal', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF1E293B)),
            onPressed: () async {
              await AuthService.logout();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF1E293B),
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined, color: Color(0xFF1E293B)),
              title: const Text('Dashboard'),
              subtitle: const Text('Back to home'),
              onTap: () {
                Navigator.pop(context);
                context.go('/student/dashboard');
              },
            ),
            for (var item in menuItems)
              ListTile(
                leading: Icon(item['icon'] as IconData, color: const Color(0xFF1E293B)),
                title: Text(item['label'] as String),
                subtitle: Text(item['description'] as String),
                onTap: () {
                  Navigator.pop(context);
                  final label = item['label'] as String;
                  if (label == 'Profile') {
                    context.go('/student/profile');
                  } else if (label == 'Virtual ID') {
                    context.go('/student/virtual-id');
                  }
                },
              ),
          ],
        ),
      ),
      body: child,
    );
  }
}
