import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _redirectUser();
  }

  Future<void> _redirectUser() async {
    // Wait a short moment to ensure the widget is built before navigating.
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // If no user is logged in, send to the login page.
      if (mounted) context.go('/login');
      return;
    }

    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (!mounted) return; // Check again after await

      if (institutionId == null) {
        // If there's no institutionId in the session, the user needs
        // to log in again to select their institution.
        context.go('/login');
        return;
      }

      final role = await AuthService.getRole(user.uid, institutionId);
      if (!mounted) return; // Check again after await

      final path = switch (role) {
        'admin' => '/$institutionId/admin/dashboard',
        'faculty' => '/$institutionId/faculty/dashboard',
        'student' => '/$institutionId/student/dashboard',
        _ => '/login', // Default to login if role is unknown or invalid
      };

      context.go(path);
    } catch (e) {
      // In case of any error fetching role or institution, it's safest
      // to send the user back to the login page.
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}