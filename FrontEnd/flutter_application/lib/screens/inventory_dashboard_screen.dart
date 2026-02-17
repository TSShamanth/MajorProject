import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application/services/session_manager.dart';

// Mock Data Models
enum ItemStatus { inStock, assigned, inMaintenance, decommissioned }

class InventoryItem {
  final String id;
  final String name;
  final String category;
  final ItemStatus status;
  final String assignedTo;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    this.assignedTo = '',
  });
}

class InventoryDashboardScreen extends StatefulWidget {
  const InventoryDashboardScreen({super.key});

  @override
  State<InventoryDashboardScreen> createState() => _InventoryDashboardScreenState();
}

class _InventoryDashboardScreenState extends State<InventoryDashboardScreen> {
  // Mock Data
  final List<InventoryItem> _items = [
    InventoryItem(id: 'DELL-LT-001', name: 'Dell Latitude 5420', category: 'Electronics', status: ItemStatus.assigned, assignedTo: 'CS Department'),
    InventoryItem(id: 'PROJ-005', name: 'Epson Projector H838A', category: 'Electronics', status: ItemStatus.inMaintenance),
    InventoryItem(id: 'CHR-ST-204', name: 'Steelcase Office Chair', category: 'Furniture', status: ItemStatus.inStock),
    InventoryItem(id: 'MIC-PHY-012', name: 'Olympus Microscope', category: 'Lab Equipment', status: ItemStatus.inStock),
     InventoryItem(id: 'HP-DSK-015', name: 'HP EliteDesk 800', category: 'Electronics', status: ItemStatus.decommissioned),
  ];
  
  String? _selectedCategory;

  void _navigateToEditor() async {
    final institutionId = await SessionManager.getInstitutionId();
    if (!mounted) return;
    if (institutionId != null) {
      context.go('/$institutionId/admin/inventory-item-editor');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _items.where((item) {
      return _selectedCategory == null || item.category == _selectedCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                return _buildItemCard(filteredItems[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToEditor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterBar() {
    // Get unique categories from mock data
    final categories = _items.map((e) => e.category).toSet().toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Search by Name or ID',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            hint: const Text('Category'),
            value: _selectedCategory,
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Categories'),
              ),
              ...categories.map((category) => DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              )),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildItemCard(InventoryItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                StatusChip(status: item.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Asset ID: ${item.id}', style: const TextStyle(color: Colors.grey)),
            if (item.assignedTo.isNotEmpty)
              Text('Assigned To: ${item.assignedTo}', style: const TextStyle(color: Colors.grey)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () {}, child: const Text('View History')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _navigateToEditor, child: const Text('Edit')),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final ItemStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case ItemStatus.inStock:
        color = Colors.green;
        label = 'In Stock';
        break;
      case ItemStatus.assigned:
        color = Colors.blue;
        label = 'Assigned';
        break;
      case ItemStatus.inMaintenance:
        color = Colors.orange;
        label = 'Maintenance';
        break;
      case ItemStatus.decommissioned:
        color = Colors.grey;
        label = 'Decommissioned';
        break;
    }
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
