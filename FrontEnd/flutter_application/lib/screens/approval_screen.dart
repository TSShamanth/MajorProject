import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ApprovalScreen extends StatelessWidget {
  const ApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final institutionId = GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approvals'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const Text('Regularisation Requests'),
            subtitle: const Text('Approve or deny regularisation requests from faculty.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (institutionId != null) {
                context.push('/$institutionId/admin/regularisation');
              }
            },
          ),
        ],
      ),
    );
  }
}
