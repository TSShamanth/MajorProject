import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/faculty_dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/student_dashboard_screen.dart';
import '../screens/student/profile_screen.dart';
import '../screens/student/edit_profile_screen.dart';
import '../screens/student/virtual_id_screen.dart';
import '../screens/mark_attendance_screen.dart';
import '../screens/attendance_history_screen.dart';
import '../screens/student_attendance_screen.dart';
import '../services/auth_service.dart';

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
          path: '/student/dashboard',
          builder: (context, state) => const StudentDashboardScreen(),
        ),
        GoRoute(
          path: '/student/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/student/virtual-id',
          builder: (context, state) => const VirtualIdScreen(),
        ),
        GoRoute(
          path: '/student/attendance',
          builder: (context, state) => const StudentAttendanceScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/student/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
      redirect: (context, state) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return '/login';
        final role = await AuthService.getRole(user.uid);
        // Only admins can access this route
        return role == 'admin' ? null : '/student/profile';
      },
    ),
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/faculty/dashboard',
      builder: (context, state) => const FacultyDashboardScreen(),
    ),
    GoRoute(
      path: '/faculty/mark-attendance',
      builder: (context, state) => const MarkAttendanceScreen(),
    ),
    GoRoute(
      path: '/faculty/attendance-history',
      builder: (context, state) => const AttendanceHistoryScreen(),
    ),
    GoRoute(
      path: '/',
      redirect: (context, state) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          return '/login';
        }
        final role = await AuthService.getRole(user.uid);
        switch (role) {
          case 'admin':
            return '/admin/dashboard';
          case 'faculty':
            return '/faculty/dashboard';
          case 'student':
            return '/student/dashboard';
          default:
            return '/login';
        }
      },
    ),
  ],
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggingIn = state.matchedLocation == '/login';

    if (user == null) {
      // User is not logged in, should redirect to /login
      return isLoggingIn ? null : '/login';
    }

    if (isLoggingIn) {
      // User is logged in, but trying to access /login, so redirect to home
      return '/';
    }

    return null;
  },
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
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
    final bool isDashboard = location == '/student/dashboard';

    if (isDashboard) {
      return child;
    }

    String title = 'Student';
    if (location == '/student/profile') {
      title = 'Profile';
    } else if (location == '/student/virtual-id') {
      title = 'Virtual ID';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            context.go('/student/dashboard');
          },
        ),
      ),
      body: child,
    );
  }
}
