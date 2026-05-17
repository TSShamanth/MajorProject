import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/api_service.dart';
import '../../../models/leave_application_model.dart';
import '../../../config/api_config.dart';
import '../../../widgets/faculty_layout.dart';

class FacultyLeaveApprovalScreen extends StatefulWidget {
  static const String routeName = '/faculty/leave-approval';

  const FacultyLeaveApprovalScreen({super.key});

  @override
  State<FacultyLeaveApprovalScreen> createState() => _FacultyLeaveApprovalScreenState();
}

class _FacultyLeaveApprovalScreenState extends State<FacultyLeaveApprovalScreen> {
  final ApiService _apiService = ApiService();
  Future<List<LeaveApplication>>? _pendingLeavesFuture;
  Future<List<LeaveApplication>>? _leaveHistoryFuture;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _fetchLeaveApplications();
  }

  void _fetchLeaveApplications() {
    setState(() {
      _pendingLeavesFuture = _apiService.getPendingLeaveApplicationsForFaculty();
      _leaveHistoryFuture = _apiService.getFacultyLeaveHistory();
    });
  }

  Future<void> _approveLeave(String leaveId) async {
    try {
      await _apiService.approveLeaveApplication(leaveId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave application approved successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
      _fetchLeaveApplications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve leave: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _rejectLeave(String leaveId) async {
    String? reason = await _showReasonDialog(context);
    if (reason == null || reason.isEmpty) return;

    try {
      await _apiService.rejectLeaveApplication(leaveId, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave application rejected successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      _fetchLeaveApplications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject leave: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<String?> _showReasonDialog(BuildContext context) {
    TextEditingController reasonController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          title: Text('Reason for Rejection', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          content: TextField(
            controller: reasonController,
            style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Enter reason here',
              hintStyle: TextStyle(color: _isDarkMode ? Colors.grey[500] : Colors.grey[400]),
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, reasonController.text),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);

    return FacultyLayout(
      title: 'Leave Requests',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Approvals', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
      ],
      child: SingleChildScrollView(
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
                      'Leave Approvals',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review and manage student leave applications',
                      style: TextStyle(fontSize: 14, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _fetchLeaveApplications,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32.0),
            _buildSectionHeader('Pending Applications', Icons.pending_actions_rounded, Colors.orange),
            const SizedBox(height: 16.0),
            FutureBuilder<List<LeaveApplication>>(
              future: _pendingLeavesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                } else if (snapshot.hasError) {
                  return _buildErrorCard(snapshot.error.toString());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState('No pending applications.', Icons.check_circle_outline_rounded);
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final leave = snapshot.data![index];
                    return _buildLeaveCard(leave, showActions: true);
                  },
                );
              },
            ),
            const SizedBox(height: 40.0),
            _buildSectionHeader('Processing History', Icons.history_rounded, const Color(0xFF4F46E5)),
            const SizedBox(height: 16.0),
            FutureBuilder<List<LeaveApplication>>(
              future: _leaveHistoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                } else if (snapshot.hasError) {
                  return _buildErrorCard(snapshot.error.toString());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState('No processing history found.', Icons.history_rounded);
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final leave = snapshot.data![index];
                    return _buildLeaveCard(leave, showActions: false);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: _isDarkMode ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildLeaveCard(LeaveApplication leave, {required bool showActions}) {
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final statusColor = _getLeaveStatusColor(leave.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (leave.studentName ?? 'U').substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leave.studentName ?? 'Unknown Student',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937)),
                        ),
                        Text(
                          leave.leaveType,
                          style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildStatusBadge(leave.status, statusColor),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today_rounded, 'Duration:', '${DateFormat('dd MMM').format(leave.startDate)} - ${DateFormat('dd MMM, yyyy').format(leave.endDate)}'),
            _buildInfoRow(Icons.description_outlined, 'Reason:', leave.reason),
            if (leave.status == 'Rejected' && leave.rejectionReason != null && leave.rejectionReason!.isNotEmpty)
              _buildInfoRow(Icons.error_outline_rounded, 'Rejection Reason:', leave.rejectionReason!, color: Colors.red),
            
            if (leave.documentUrl != null && leave.documentUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: InkWell(
                  onTap: () => _openDocument(leave.documentUrl!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attachment_rounded, size: 16, color: Color(0xFF4F46E5)),
                        SizedBox(width: 8),
                        Text('View Document', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            
            if (showActions) ...[
              const SizedBox(height: 16),
              _AiLeaveInsight(
                onGetInsight: () => _apiService.getLeaveInsight(
                  'RVU', // Fallback or dynamic institution ID
                  leave.studentId ?? '', 
                  DateFormat('yyyy-MM-dd').format(leave.startDate), 
                  DateFormat('yyyy-MM-dd').format(leave.endDate)
                ),
                isDarkMode: _isDarkMode,
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _rejectLeave(leave.id),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  ElevatedButton.icon(
                    onPressed: () => _approveLeave(leave.id),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _isDarkMode ? Colors.grey[500] : Colors.grey[400]),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: color ?? (_isDarkMode ? Colors.grey[300] : Colors.black87)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Future<void> _openDocument(String url) async {
    try {
      final fullUrl = url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url';
      if (await canLaunchUrl(Uri.parse(fullUrl))) {
        await launchUrl(Uri.parse(fullUrl), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open document')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Color _getLeaveStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }
}

class _AiLeaveInsight extends StatefulWidget {
  final Future<String> Function() onGetInsight;
  final bool isDarkMode;

  const _AiLeaveInsight({required this.onGetInsight, required this.isDarkMode});

  @override
  State<_AiLeaveInsight> createState() => _AiLeaveInsightState();
}

class _AiLeaveInsightState extends State<_AiLeaveInsight> {
  String? _insight;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF4F46E5), size: 18),
              const SizedBox(width: 8),
              const Text(
                'AI LEAVE ASSISTANT',
                style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
              ),
              const Spacer(),
              if (_insight == null && !_isLoading)
                TextButton(
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      final result = await widget.onGetInsight();
                      setState(() {
                        _insight = result;
                        _isLoading = false;
                      });
                    } catch (e) {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: const Text('Get Insight', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
          if (_insight != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: MarkdownBody(
                data: _insight!,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 13,
                    color: widget.isDarkMode ? Colors.grey[300] : const Color(0xFF374151),
                    fontStyle: FontStyle.italic,
                  ),
                  strong: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
