import 'package:flutter/material.dart';
import 'package:flutter_application/models/regularisation_request_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RegularisationStatusScreen extends StatefulWidget {
  const RegularisationStatusScreen({super.key});

  @override
  State<RegularisationStatusScreen> createState() => _RegularisationStatusScreenState();
}

class _RegularisationStatusScreenState extends State<RegularisationStatusScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<RegularisationRequest>> _requests;

  @override
  void initState() {
    super.initState();
    _refreshRequests();
  }

  void _refreshRequests() {
    final institutionId = GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'];
    setState(() {
      if (institutionId != null) {
        _requests = _apiService.getMyRegularisationRequests(institutionId);
      } else {
        _requests = Future.value([]);
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'denied':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String? type) {
    if (type == null) return Icons.help_outline;
    switch (type.toLowerCase()) {
      case 'clock-in':
        return Icons.login;
      case 'clock-out':
        return Icons.logout;
      case 'full-day':
        return Icons.event_available;
      default:
        return Icons.history;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Regularisation Status', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRequests,
          ),
        ],
      ),
      body: FutureBuilder<List<RegularisationRequest>>(
        future: _requests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  TextButton(onPressed: _refreshRequests, child: const Text('Retry')),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No requests found', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          final requests = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final statusColor = _getStatusColor(request.status);
              final dateStr = DateFormat('EEE, dd MMM yyyy').format(request.targetDate);

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(_getTypeIcon(request.type), color: theme.primaryColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.type ?? 'General Request',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    dateStr,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              request.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Text(
                        'Reason:',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.reason,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                      if (request.approvedOn != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, size: 14, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                'Approved on ${DateFormat('dd MMM').format(request.approvedOn!)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
