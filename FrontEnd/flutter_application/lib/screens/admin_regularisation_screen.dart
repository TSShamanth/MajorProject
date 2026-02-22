import 'package:flutter/material.dart';
import 'package:flutter_application/models/regularisation_request_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:go_router/go_router.dart';

class AdminRegularisationScreen extends StatefulWidget {
  const AdminRegularisationScreen({super.key});

  @override
  State<AdminRegularisationScreen> createState() => _AdminRegularisationScreenState();
}

class _AdminRegularisationScreenState extends State<AdminRegularisationScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<RegularisationRequest>> _pendingRequests;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  void _loadPendingRequests() {
    final institutionId = GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'];
    if (institutionId != null) {
      setState(() {
        _pendingRequests = _apiService.getPendingRegularisationRequests(institutionId);
      });
    } else {
      setState(() {
        _pendingRequests = Future.value([]);
      });
    }
  }

  Future<void> _approveRequest(String requestId) async {
    try {
      final institutionId = GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'];
      if (institutionId == null) {
        throw Exception("Institution ID not found");
      }
      await _apiService.approveRegularisationRequest(institutionId, requestId);
      _loadPendingRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve request: $e')),
      );
    }
  }

  Future<void> _denyRequest(String requestId) async {
    try {
      final institutionId = GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'];
      if (institutionId == null) {
        throw Exception("Institution ID not found");
      }
      await _apiService.denyRegularisationRequest(institutionId, requestId);
      _loadPendingRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to deny request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Regularisation Requests'),
      ),
      body: FutureBuilder<List<RegularisationRequest>>(
        future: _pendingRequests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No pending requests.'));
          }

          final requests = snapshot.data!;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Faculty ID: ${request.facultyId}'),
                      Text('Date: ${request.targetDate.toLocal()}'.split(' ')[0]),
                      if (request.targetTime != null) Text('Time: ${request.targetTime}'),
                      if (request.type != null) Text('Type: ${request.type}'),
                      if (request.newClockInTime != null) Text('New Clock-in: ${request.newClockInTime}'),
                      if (request.newClockOutTime != null) Text('New Clock-out: ${request.newClockOutTime}'),
                      Text('Reason: ${request.reason}'),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _denyRequest(request.id),
                            child: const Text('Deny'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _approveRequest(request.id),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
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
