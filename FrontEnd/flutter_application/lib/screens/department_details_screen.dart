import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DepartmentDetailsScreen extends StatelessWidget {
  final String departmentName;

  const DepartmentDetailsScreen({
    super.key,
    required this.departmentName,
  });

  void _navigateToManagementScreen(BuildContext context, String assetType) {
    // A bit brittle, but works for mock. A better way is to get this from the state manager.
    final currentPath = GoRouter.of(context).routeInformationProvider.value.uri.path;
    final pathSegments = Uri.parse(currentPath).pathSegments;
    if (pathSegments.isNotEmpty) {
      final institutionId = pathSegments[0];
       context.go('/$institutionId/admin/institution-settings/$departmentName/$assetType');
    } else {
      // Handle error: couldn't determine institutionId
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not determine institution ID.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(departmentName),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildManagementCard(
            context,
            title: 'Manage Courses',
            icon: Icons.book_outlined,
            description: 'Add or edit courses offered by this department.',
            onTap: () => _navigateToManagementScreen(context, 'Courses'),
          ),
          const SizedBox(height: 16),
          _buildManagementCard(
            context,
            title: 'Manage Faculty',
            icon: Icons.people_outline,
            description: 'Assign or add new faculty members.',
            onTap: () => _navigateToManagementScreen(context, 'Faculty'),
          ),
          const SizedBox(height: 16),
          _buildManagementCard(
            context,
            title: 'Manage Students',
            icon: Icons.school_outlined,
            description: 'Enroll or view students in this department.',
            onTap: () => _navigateToManagementScreen(context, 'Students'),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          foregroundColor: Theme.of(context).primaryColor,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
