import 'package:flutter/material.dart';
import 'package:flutter_application/models/regularisation_request_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/widgets/faculty_shell.dart';
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
  final ApiService _apiService = ApiService();
  late Future<List<RegularisationRequest>> _requests;
  String? _institutionId;

  // ── Status colour + icon ───────────────────────────────────────────────────
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'pending':
        return Icons.access_time_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  // ── Request type icon ──────────────────────────────────────────────────────
  IconData _getTypeIcon(String? type) =>
      (type ?? '').toLowerCase().contains('in')
          ? Icons.login_rounded
          : Icons.logout_rounded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _institutionId = GoRouter.of(context)
          .routerDelegate
          .currentConfiguration
          .pathParameters['institutionId'];
      _refresh();
    });
    _requests = Future.value([]);
  }

  void _refresh() {
    if (_institutionId != null) {
      setState(() {
        _requests = _apiService.getMyRegularisationRequests(_institutionId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FacultyShell(
      title: 'Regularisation Status',
      child: FutureBuilder<List<RegularisationRequest>>(
        future: _requests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final requests = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                final color = _getStatusColor(req.status);
                final icon = _getStatusIcon(req.status);
                final typeIcon = _getTypeIcon(req.type);

                return _buildRequestCard(req, color, icon, typeIcon);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined,
              size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No regularisation requests found.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(RegularisationRequest req, Color statusColor,
      IconData statusIcon, IconData typeIcon) {
    final dateStr = DateFormat('EEE, MMM d, yyyy').format(req.targetDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeIcon, color: const Color(0xFF4F46E5), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.type ?? 'Clock Regularisation',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(req.status, statusColor, statusIcon),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF3F4F6)),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_rounded, size: 16, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    req.reason,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (req.approvedBy != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Text(
                      'Approved by Admin',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
