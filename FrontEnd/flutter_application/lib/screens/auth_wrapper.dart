import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_dashboard_screen.dart';
import 'faculty_dashboard_screen.dart';
import 'login_screen.dart';
import 'student_dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          if (user.email != null) {
            return FutureBuilder<String>(
              future: AuthService.getRole(user.uid),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (roleSnapshot.hasData) {
                  switch (roleSnapshot.data) {
                    case 'admin':
                      return const AdminDashboardScreen();
                    case 'faculty':
                      return const FacultyDashboardScreen();
                    case 'student':
                      return const StudentDashboardScreen();
                    default:
                      return const LoginScreen();
                  }
                } else {
                  // Handle error or no role found
                  return const LoginScreen();
                }
              },
            );
          }
        }
        
        return const LoginScreen();
      },
    );
  }
}
