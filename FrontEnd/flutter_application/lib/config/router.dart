import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/auth_wrapper.dart';
import '../screens/faculty_dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/student_dashboard_screen.dart';
import '../screens/student/profile_screen.dart';
import '../screens/student/edit_profile_screen.dart';
import '../screens/student/virtual_id_screen.dart';
import '../screens/mark_attendance_screen.dart';
import '../screens/attendance_history_screen.dart';
import '../screens/student_attendance_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return StudentShell(state: state, child: child);
      },
      routes: [
        GoRoute(
          path: '/:institutionId/student/dashboard',
          builder: (context, state) => const StudentDashboardScreen(),
        ),
        GoRoute(
          path: '/:institutionId/student/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/:institutionId/student/virtual-id',
          builder: (context, state) => const VirtualIdScreen(),
        ),
        GoRoute(
          path: '/:institutionId/student/attendance',
          builder: (context, state) => const StudentAttendanceScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/:institutionId/student/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/:institutionId/faculty/dashboard',
      builder: (context, state) => const FacultyDashboardScreen(),
    ),
    GoRoute(
      path: '/:institutionId/faculty/mark-attendance',
      builder: (context, state) => const MarkAttendanceScreen(),
    ),
    GoRoute(
      path: '/:institutionId/faculty/attendance-history',
      builder: (context, state) => const AttendanceHistoryScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthWrapper(),
    ),
  ],
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (BuildContext context, GoRouterState state) async {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggingIn = state.matchedLocation == '/login';

    // 1. User is not logged in
    if (user == null) {
      // If they are not on the login page, send them there.
      return isLoggingIn ? null : '/login';
    }

    // 2. User IS logged in and is trying to access the login page
    if (isLoggingIn) {
      // Redirect a logged-in user away from the login page.
      // Sending them to the root is a safe choice, as it will be
      // handled by a nested route or another redirect if necessary.
      return '/';
    }

    // 3. User is logged in and not on the login page. Allow navigation.
    return null;
  },
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class StudentShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const StudentShell({super.key, required this.child, required this.state});

  @override
  Widget build(BuildContext context) {
    final location = state.uri.toString();
    final institutionId = state.pathParameters['institutionId'];
    final bool isDashboard = location == '/$institutionId/student/dashboard';

    if (isDashboard) {
      return child;
    }

    String title = 'Student';
    if (location == '/$institutionId/student/profile') {
      title = 'Profile';
    } else if (location == '/$institutionId/student/virtual-id') {
      title = 'Virtual ID';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            context.go('/$institutionId/student/dashboard');
          },
        ),
      ),
      body: child,
    );
  }
}
