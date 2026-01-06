import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'auth_service.dart';

class SessionManager extends StatefulWidget {
  final Widget child;
  final GoRouter router;

  const SessionManager({
    super.key,
    required this.child,
    required this.router,
  });

  @override
  State<SessionManager> createState() => _SessionManagerState();
}

class _SessionManagerState extends State<SessionManager> {
  Timer? _sessionTimer;
  StreamSubscription? _authSubscription;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes to start/stop the timer appropriately.
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });

      if (_currentUser == null) {
        _sessionTimer?.cancel();
        debugPrint("Session timer cancelled: User is logged out.");
      } else {
        _startSessionTimer();
        debugPrint("Session timer started: User is logged in.");
      }
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    // Only start the timer if a user is logged in.
    if (_currentUser != null) {
      _sessionTimer = Timer(const Duration(minutes: 2), _logout);
      debugPrint("Session timer (re)started for 10 seconds.");
    }
  }

  void _resetSessionTimer() {
    // Only reset the timer if a user is logged in.
    if (_currentUser != null) {
      _startSessionTimer();
    }
  }

  void _logout() {
    _sessionTimer?.cancel();
    debugPrint("Session timeout: Logging out user.");
    AuthService.logout();
    // The authStateChanges listener in router.dart will handle the redirect.
  }

  @override
  Widget build(BuildContext context) {
    // The Listener will reset the timer on any user interaction.
    return Listener(
      onPointerDown: (_) => _resetSessionTimer(),
      onPointerMove: (_) => _resetSessionTimer(),
      onPointerUp: (_) => _resetSessionTimer(),
      child: widget.child,
    );
  }
}
