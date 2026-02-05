import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application/services/session_manager.dart';


// Mock Data Models
class FeeStructure {
  final String id;
  final String title;
  final double totalAmount;
  final int applicableBatches;

  FeeStructure({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.applicableBatches,
  });
}

class FeeManagementDashboardScreen extends StatefulWidget {
  const FeeManagementDashboardScreen({super.key});

  @override
  State<FeeManagementDashboardScreen> createState() =>
      _FeeManagementDashboardScreenState();
}

class _FeeManagementDashboardScreenState
    extends State<FeeManagementDashboardScreen> {
  // Mock data
  final List<FeeStructure> _feeStructures = [
    FeeStructure(id: 'fs_01', title: 'B.Tech CSE - 2024 Batch', totalAmount: 250000, applicableBatches: 1),
    FeeStructure(id: 'fs_02', title: 'B.B.A. - 2024 Batch', totalAmount: 180000, applicableBatches: 1),
    FeeStructure(id: 'fs_03', title: 'Hostel & Mess Fees (Annual)', totalAmount: 85000, applicableBatches: 5),
  ];

  void _navigateToEditor() async {
    final institutionId = await SessionManager.getInstitutionId();
     if (!mounted) return;
    if (institutionId != null) {
      context.go('/$institutionId/admin/fee-structure-editor');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Management'),
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
            _buildFeeStructuresSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToEditor,
        icon: const Icon(Icons.add),
        label: const Text('New Fee Structure'),
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
      childAspectRatio: 1.8,
      children: const [
        StatCard(
          title: 'Total Fees Collected',
          value: '₹1.25 Cr',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        StatCard(
          title: 'Total Dues',
          value: '₹45.5 Lakh',
          icon: Icons.error_outline,
          color: Colors.orange,
        ),
        StatCard(
          title: 'Overdue Payments',
          value: '₹12.0 Lakh',
          icon: Icons.dangerous_outlined,
          color: Colors.red,
        ),
        StatCard(
          title: 'Upcoming Payments',
          value: '₹80.0 Lakh',
          icon: Icons.hourglass_top_outlined,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildFeeStructuresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fee Structures',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._feeStructures.map((structure) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              title: Text(structure.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${structure.applicableBatches} Batches/Groups'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('₹${(structure.totalAmount / 100000).toStringAsFixed(2)} L', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: _navigateToEditor,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
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
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: TextStyle(color: color)),
            ],
          ),
        ],
      ),
    );
  }
}
