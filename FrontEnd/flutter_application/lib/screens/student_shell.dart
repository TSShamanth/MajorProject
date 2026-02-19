import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const StudentShell({super.key, required this.child, required this.state});

  @override
  Widget build(BuildContext context) {
    final location = state.uri.toString();
    final institutionId = state.pathParameters['institutionId'];
    final bool isDashboard = location == '/$institutionId/student/dashboard';

    // The dashboard screen has its own scaffold, other screens get this default one.
    if (isDashboard) {
      return child;
    }

    String title = 'Student Portal';
    if (location.contains('/student/profile')) {
      title = 'My Profile';
    } else if (location.contains('/student/virtual-id')) {
      title = 'Virtual ID';
    } else if (location.contains('/student/leave')) {
      title = 'Leave Management';
    } else if (location.contains('/student/fees')) {
      title = 'My Fees';
    } else if (location.contains('/student/attendance')) {
      title = 'My Attendance';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/$institutionId/student/dashboard');
            }
          },
        ),
      ),
      body: child,
    );
  }
}
