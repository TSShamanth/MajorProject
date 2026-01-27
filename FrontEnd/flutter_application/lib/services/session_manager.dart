import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const String _institutionIdKey = 'institutionId';

  static Future<void> setInstitutionId(String institutionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_institutionIdKey, institutionId);
  }

  static Future<String?> getInstitutionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_institutionIdKey);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_institutionIdKey);
  }
}

class _SessionManagerState extends State<SessionManager> {
  Timer? _sessionTimer;
  StreamSubscription? _authSubscription;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
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
    if (_currentUser != null) {
      _sessionTimer = Timer(const Duration(minutes: 2), _logout);
      debugPrint("Session timer (re)started for 2 minutes.");
    }
  }

  void _resetSessionTimer() {
    if (_currentUser != null) {
      _startSessionTimer();
    }
  }

  void _logout() {
    _sessionTimer?.cancel();
    debugPrint("Session timeout: Logging out user.");
    SessionManager.clearSession();
    AuthService.logout();
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
