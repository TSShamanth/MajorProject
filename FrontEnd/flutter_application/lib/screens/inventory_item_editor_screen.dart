import 'package:flutter/material.dart';

class InventoryItemEditorScreen extends StatefulWidget {
  const InventoryItemEditorScreen({super.key});

  @override
  State<InventoryItemEditorScreen> createState() => _InventoryItemEditorScreenState();
}

class _InventoryItemEditorScreenState extends State<InventoryItemEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _status = 'In Stock';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Inventory Item'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Mock save action
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item saved (mocked)')),
                );
                Navigator.of(context).pop();
              }
            },
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Item Details'),
              TextFormField(
                initialValue: 'Dell Latitude 5420',
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: 'Electronics',
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: ['Electronics', 'Furniture', 'Lab Equipment', 'Sports', 'Other']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: 'DELL-LT-001',
                decoration: const InputDecoration(labelText: 'Asset ID'),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Purchase Information'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '2023-01-15',
                      decoration: const InputDecoration(labelText: 'Purchase Date', hintText: 'YYYY-MM-DD'),
                    ),
                  ),
                  const SizedBox(width: 16),
                   Expanded(
                    child: TextFormField(
                      initialValue: '65000',
                      decoration: const InputDecoration(labelText: 'Purchase Cost', prefixText: '₹'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
               TextFormField(
                initialValue: 'Dell Inc.',
                decoration: const InputDecoration(labelText: 'Vendor / Supplier'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: '2026-01-14',
                decoration: const InputDecoration(labelText: 'Warranty Expiry', hintText: 'YYYY-MM-DD'),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Status & Assignment'),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: ['In Stock', 'Assigned', 'In Maintenance', 'Decommissioned']
                    .map((stat) => DropdownMenuItem(value: stat, child: Text(stat)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value;
                  });
                },
              ),
              if (_status == 'Assigned')
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
                     initialValue: 'CS Department',
                    decoration: const InputDecoration(labelText: 'Assigned To (Department or Person)'),
                  ),
                ),
              const SizedBox(height: 24),
               _buildSectionTitle('Notes'),
               TextFormField(
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Add any relevant notes here...',
                  border: OutlineInputBorder()
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor),
      ),
    );
  }
}
