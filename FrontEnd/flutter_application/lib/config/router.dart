import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/faculty_dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/student_dashboard_screen.dart';
import '../services/auth_service.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/student/dashboard',
      builder: (context, state) => const StudentDashboardScreen(),
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
