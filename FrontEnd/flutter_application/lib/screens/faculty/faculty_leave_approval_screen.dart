import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:provider/provider.dart'; // Not used in this screen, can be removed
import '../../../services/api_service.dart';
import '../../../models/leave_application_model.dart';
import '../../../config/api_config.dart';
// import '../../../models/user_model.dart'; // Not directly used in this screen, can be removed

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
        const SnackBar(content: Text('Leave application approved successfully!')),
      );
      _fetchLeaveApplications(); // Refresh both lists
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve leave: $e')),
      );
    }
  }

  Future<void> _rejectLeave(String leaveId) async {
    String? reason = await _showReasonDialog(context);
    if (reason == null || reason.isEmpty) {
      return; // User cancelled or didn't provide a reason
    }

    try {
      await _apiService.rejectLeaveApplication(leaveId, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave application rejected successfully!')),
      );
      _fetchLeaveApplications(); // Refresh both lists
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject leave: $e')),
      );
    }
  }

  Future<String?> _showReasonDialog(BuildContext context) {
    TextEditingController reasonController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reason for Rejection'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(hintText: 'Enter reason here'),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: const Text('Submit'),
              onPressed: () {
                Navigator.pop(context, reasonController.text);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Approval'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Applications',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            FutureBuilder<List<LeaveApplication>>(
              future: _pendingLeavesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading pending leave applications: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No pending leave applications.'));
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
            const SizedBox(height: 32.0),
            Text(
              'Approved / Rejected History',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            FutureBuilder<List<LeaveApplication>>(
              future: _leaveHistoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading leave history: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No leave history found.'));
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

  Widget _buildLeaveCard(LeaveApplication leave, {required bool showActions}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student: ${leave.studentName ?? 'Unknown Student'}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            _buildInfoRow('Leave Type:', leave.leaveType),
            _buildInfoRow('Dates:', '${DateFormat('dd/MM/yyyy').format(leave.startDate)} - ${DateFormat('dd/MM/yyyy').format(leave.endDate)}'),
            _buildInfoRow('Reason:', leave.reason),
            _buildInfoRow('Status:', leave.status, color: _getLeaveStatusColor(leave.status)),
            if (leave.status == 'Rejected' && leave.rejectionReason != null && leave.rejectionReason!.isNotEmpty)
              _buildInfoRow('Rejection Reason:', leave.rejectionReason!),
            if (leave.documentUrl != null && leave.documentUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: InkWell(
                  onTap: () async {
                    try {
                      // Construct full URL if it's a relative path
                      final url = leave.documentUrl!.startsWith('http')
                          ? leave.documentUrl!
                          : '${ApiConfig.baseUrl}${leave.documentUrl!}';
                      
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open document')),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error opening document: $e')),
                        );
                      }
                    }
                  },
                  child: Text(
                    'View Document',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            if (showActions)
              Column(
                children: [
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _rejectLeave(leave.id),
                        child: const Text('Reject', style: TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () => _approveLeave(leave.id),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLeaveStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green.shade700;
      case 'pending':
        return Colors.orange.shade700;
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}