import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application/services/session_manager.dart';

class AlumniDashboardScreen extends StatefulWidget {
  const AlumniDashboardScreen({super.key});

  @override
  State<AlumniDashboardScreen> createState() => _AlumniDashboardScreenState();
}

class _AlumniDashboardScreenState extends State<AlumniDashboardScreen> {
  Future<void> _navigateTo(String route) async {
    final institutionId = await SessionManager.getInstitutionId();
    if (!mounted) return;
    if (institutionId != null) {
      context.go('/$institutionId/admin/$route');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumni Network Portal'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildFeatureCard(
              context,
              icon: Icons.search,
              title: 'Alumni Directory',
              subtitle: 'Search and filter the entire alumni database.',
              color: Colors.blue,
              onTap: () => _navigateTo('alumni-directory'),
            ),
            _buildFeatureCard(
              context,
              icon: Icons.work_outline,
              title: 'Job Board',
              subtitle: 'View and post job opportunities from alumni.',
              color: Colors.green,
              onTap: () => _navigateTo('alumni-job-board'),
            ),
             _buildFeatureCard(
              context,
              icon: Icons.event,
              title: 'Alumni Events',
              subtitle: 'Create and manage alumni meetups and reunions.',
              color: Colors.orange,
              onTap: () {},
            ),
            _buildFeatureCard(
              context,
              icon: Icons.favorite_border,
              title: 'Donation Campaigns',
              subtitle: 'Manage fundraising and donation drives.',
              color: Colors.red,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.2,
      children: const [
        StatCard(title: 'Total Alumni', value: '1,250', icon: Icons.group, color: Colors.blue),
        StatCard(title: 'New Members (This Year)', value: '180', icon: Icons.person_add, color: Colors.green),
        
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
