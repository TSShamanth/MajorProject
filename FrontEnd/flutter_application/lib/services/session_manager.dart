import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../screens/login_screen.dart';

class SessionManager extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const SessionManager({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<SessionManager> createState() => _SessionManagerState();
}

class _SessionManagerState extends State<SessionManager> {
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(minutes: 2), _logout);
  }

  void _resetSessionTimer() {
    _startSessionTimer();
  }

  void _logout() {
    _sessionTimer?.cancel();
    AuthService.logout();

    // Use the provided navigator key to push the login screen.
    final navigator = widget.navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetSessionTimer(),
      onPointerMove: (_) => _resetSessionTimer(),
      onPointerUp: (_) => _resetSessionTimer(),
      child: widget.child,
    );
  }
}
