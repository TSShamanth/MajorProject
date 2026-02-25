import 'package:flutter/material.dart';
import 'package:flutter_application/models/regularisation_request_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RegularisationStatusScreen extends StatefulWidget {
  const RegularisationStatusScreen({super.key});

  @override
  State<RegularisationStatusScreen> createState() =>
      _RegularisationStatusScreenState();
}

class _RegularisationStatusScreenState
    extends State<RegularisationStatusScreen> {
  // ── Data ───────────────────────────────────────────────────────────────────
  final ApiService _apiService = ApiService();
  late Future<List<RegularisationRequest>> _requests;

  // ── Shell state ────────────────────────────────────────────────────────────
  bool _sidebarExpanded = true;
  bool _isDarkMode = false;
  String? _institutionId;

  // ── Theme helpers ──────────────────────────────────────────────────────────
  Color get _bgColor =>
      _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
  Color get _cardColor =>
      _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
  Color get _textPrimary =>
      _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
  Color get _textSecondary =>
      _isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get _borderColor =>
      _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

  static const _accent  = Color(0xFF4F46E5);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _danger  = Color(0xFFEF4444);
  static const _purple  = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    final institutionId = GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'];
    if (institutionId != null) {
      _requests = _apiService.getMyRegularisationRequests(institutionId);
    } else {
      // Handle the case where institutionId is null
      _requests = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regularisation Status'),
      ),
      body: FutureBuilder<List<RegularisationRequest>>(
        future: _requests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No regularisation requests found.'));
          }

          final requests = snapshot.data!;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return ListTile(
                title: Text('${request.type} on ${request.targetDate.toLocal()}'.split(' ')[0]),
                subtitle: Text('Reason: ${request.reason}'),
                trailing: Text(request.status),
              );
            },
          );
        },
      ),
    );
  }
}