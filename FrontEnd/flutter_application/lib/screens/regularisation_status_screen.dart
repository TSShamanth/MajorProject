import 'package:flutter/material.dart';
import 'package:flutter_application/models/regularisation_request_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void initState() {
    super.initState();
    final institutionId = GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'];
    if (institutionId != null) {
      _requests = _apiService.getMyRegularisationRequests(institutionId);
    } else {
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
