import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Mock Data Model
class FeeComponent {
  TextEditingController nameController;
  TextEditingController amountController;

  FeeComponent({required String name, required double amount})
      : nameController = TextEditingController(text: name),
        amountController = TextEditingController(text: amount.toString());
}

class FeeStructureEditorScreen extends StatefulWidget {
  const FeeStructureEditorScreen({super.key});

  @override
  State<FeeStructureEditorScreen> createState() =>
      _FeeStructureEditorScreenState();
}

class _FeeStructureEditorScreenState extends State<FeeStructureEditorScreen> {
  final _titleController = TextEditingController(text: 'B.Tech CSE - 2024 Batch');
  final List<FeeComponent> _components = [
    FeeComponent(name: 'Tuition Fee', amount: 210000),
    FeeComponent(name: 'Lab & Equipment Fee', amount: 15000),
    FeeComponent(name: 'Library Fee', amount: 5000),
    FeeComponent(name: 'Examination Fee', amount: 20000),
  ];
  double _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _calculateTotal();
    for (var component in _components) {
      component.amountController.addListener(_calculateTotal);
    }
  }

  void _calculateTotal() {
    double total = 0;
    for (var component in _components) {
      total += double.tryParse(component.amountController.text) ?? 0;
    }
    setState(() {
      _totalAmount = total;
    });
  }

  void _addComponent() {
    final newComponent = FeeComponent(name: '', amount: 0);
    newComponent.amountController.addListener(_calculateTotal);
    setState(() {
      _components.add(newComponent);
    });
  }

  void _removeComponent(int index) {
    _components[index].amountController.removeListener(_calculateTotal);
    setState(() {
      _components.removeAt(index);
    });
    _calculateTotal();
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var component in _components) {
      component.nameController.dispose();
      component.amountController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Structure Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            onPressed: () {
              // Mock save
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fee Structure Saved! (mocked)')),
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Fee Structure Title',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text(
              'Fee Components',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _components.length,
              itemBuilder: (context, index) {
                return _buildComponentRow(index);
              },
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _addComponent,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Component'),
            ),
            const SizedBox(height: 32),
            _buildTotalCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: _components[index].nameController,
              decoration: const InputDecoration(
                labelText: 'Component Name',
                border: UnderlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _components[index].amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
                border: UnderlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () => _removeComponent(index),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return Card(
      elevation: 4,
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Amount',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            Text(
              '₹${_totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
