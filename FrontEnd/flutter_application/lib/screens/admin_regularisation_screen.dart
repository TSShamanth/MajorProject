import 'package:flutter/material.dart';
import 'package:flutter_application/models/regularisation_request_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_layout.dart';

class AdminRegularisationScreen extends StatefulWidget {
  const AdminRegularisationScreen({super.key});

  @override
  State<AdminRegularisationScreen> createState() => _AdminRegularisationScreenState();
}

class _AdminRegularisationScreenState extends State<AdminRegularisationScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<RegularisationRequest>> _pendingRequests;
  String? _institutionId;
  bool _isProcessing = false;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _pendingRequests = Future.value([]); // Initialize with empty
    _initData();
  }

  Future<void> _initData() async {
    final id = await SessionManager.getInstitutionId();
    if (mounted) {
      setState(() {
        _institutionId = id;
      });
      _loadPendingRequests();
    }
  }

  void _loadPendingRequests() {
    if (_institutionId != null) {
      setState(() {
        _pendingRequests = _apiService.getPendingRegularisationRequests(_institutionId!);
      });
    }
  }

  Future<void> _handleAction(String requestId, bool approve) async {
    if (_isProcessing || _institutionId == null) return;
    
    setState(() => _isProcessing = true);
    
    try {
      if (approve) {
        await _apiService.approveRegularisationRequest(_institutionId!, requestId);
      } else {
        await _apiService.denyRegularisationRequest(_institutionId!, requestId);
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Request approved successfully' : 'Request denied'),
          backgroundColor: approve ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadPendingRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Operation failed: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: 'Regularisation Requests',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        InkWell(
          onTap: () {
            if (_institutionId != null) context.go('/$_institutionId/admin/approval');
          },
          child: Text('Approvals', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Regularisation', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Regularisation',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review and approve attendance correction requests from faculty',
                      style: TextStyle(fontSize: 14, color: textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _loadPendingRequests,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: FutureBuilder<List<RegularisationRequest>>(
                future: _pendingRequests,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return _buildEmptyState(
                      'Error Loading Requests',
                      'Something went wrong while fetching requests.',
                      Icons.error_outline_rounded,
                      Colors.redAccent,
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(
                      'No Pending Requests',
                      'All regularisation requests have been processed.',
                      Icons.assignment_turned_in_rounded,
                      const Color(0xFF10B981),
                    );
                  }

                  final requests = snapshot.data!;
                  return ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      return _buildRequestCard(requests[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 64),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(RegularisationRequest request) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                  child: const Icon(Icons.person_rounded, color: Color(0xFF4F46E5)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Faculty ID: ${request.facultyId}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Request Date: ${request.targetDate.toLocal().toString().split(' ')[0]}',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.type ?? 'Correction',
                    style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 4,
              children: [
                _buildInfoRow('New Clock-In', request.newClockInTime ?? '--:--'),
                _buildInfoRow('New Clock-Out', request.newClockOutTime ?? '--:--'),
                _buildInfoRow('Target Time', request.targetTime ?? '--:--'),
                _buildInfoRow('Type', request.type ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF111827) : Colors.grey[50]!,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor.withOpacity(0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reason: ${request.reason}',
                      style: TextStyle(fontSize: 13, color: textPrimary, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _isProcessing ? null : () => _handleAction(request.id, false),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Deny'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : () => _handleAction(request.id, true),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Approve Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: _isDarkMode ? Colors.grey[500]! : Colors.grey[500]!)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937))),
      ],
    );
  }
}
