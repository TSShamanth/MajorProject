import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/models/fee_structure_model.dart';
import 'package:flutter_application/models/fee_component_model.dart' as model;
import 'package:flutter_application/models/department_model.dart';
import 'package:flutter_application/services/fee_service.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/widgets/admin_layout.dart';
import 'package:go_router/go_router.dart';

class FeeComponentController {
  final TextEditingController nameController;
  final TextEditingController amountController;

  FeeComponentController({required String name, required double amount})
      : nameController = TextEditingController(text: name),
        amountController = TextEditingController(text: amount.toString());

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}

class FeeStructureEditorScreen extends StatefulWidget {
  final FeeStructure? feeStructure;

  const FeeStructureEditorScreen({super.key, this.feeStructure});

  @override
  State<FeeStructureEditorScreen> createState() =>
      _FeeStructureEditorScreenState();
}

class _FeeStructureEditorScreenState extends State<FeeStructureEditorScreen> {
  final FeeService _feeService = FeeService();
  final ApiService _apiService = ApiService();
  
  final _titleController = TextEditingController();
  final List<FeeComponentController> _componentControllers = [];
  
  String? _selectedDepartment = 'ALL';
  String? _selectedSemester = 'ALL';
  List<Department> _departments = [];
  bool _isLoading = true;
  String? _institutionId;
  double _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      _institutionId = await SessionManager.getInstitutionId();
      if (_institutionId != null) {
        final departments = await _apiService.getDepartments(_institutionId!);
        setState(() {
          _departments = departments;
        });
      }

      if (widget.feeStructure != null) {
        _titleController.text = widget.feeStructure!.title;
        _selectedDepartment = widget.feeStructure!.departmentId;
        _selectedSemester = widget.feeStructure!.semester;
        for (var component in widget.feeStructure!.components) {
          _addComponent(name: component.name, amount: component.amount);
        }
      } else {
        _addComponent(name: 'Tuition Fee', amount: 0);
      }
      _calculateTotal();
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotal() {
    double total = 0;
    for (var controller in _componentControllers) {
      total += double.tryParse(controller.amountController.text) ?? 0;
    }
    setState(() {
      _totalAmount = total;
    });
  }

  void _addComponent({String name = '', double amount = 0}) {
    final controller = FeeComponentController(name: name, amount: amount);
    controller.amountController.addListener(_calculateTotal);
    setState(() {
      _componentControllers.add(controller);
    });
  }

  void _removeComponent(int index) {
    _componentControllers[index].amountController.removeListener(_calculateTotal);
    _componentControllers[index].dispose();
    setState(() {
      _componentControllers.removeAt(index);
    });
    _calculateTotal();
  }

  Future<void> _saveFeeStructure() async {
    if (_titleController.text.isEmpty || _institutionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    final List<model.FeeComponent> components = _componentControllers
        .where((c) => c.nameController.text.isNotEmpty)
        .map((c) => model.FeeComponent(
              name: c.nameController.text,
              amount: double.tryParse(c.amountController.text) ?? 0,
            ))
        .toList();

    final newStructure = FeeStructure(
      id: widget.feeStructure?.id ?? '',
      title: _titleController.text,
      institutionId: _institutionId!,
      departmentId: _selectedDepartment ?? 'ALL',
      semester: _selectedSemester ?? 'ALL',
      components: components,
      totalAmount: _totalAmount,
    );

    try {
      if (widget.feeStructure == null) {
        await _feeService.createFeeStructure(_institutionId!, newStructure);
      } else {
        await _feeService.updateFeeStructure(_institutionId!, newStructure);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fee Structure Saved!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _componentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: widget.feeStructure == null ? 'New Fee Structure' : 'Edit Fee Structure',
      breadcrumbs: [
        const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        InkWell(
          onTap: () => context.pop(),
          child: const Text('Fee Management', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        Text(widget.feeStructure == null ? 'Create' : 'Edit', 
          style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 13, fontWeight: FontWeight.bold)),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGeneralInfoSection(),
                  const SizedBox(height: 32),
                  _buildComponentsSection(),
                  const SizedBox(height: 32),
                  _buildTotalCard(),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _saveFeeStructure,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Structure'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGeneralInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('General Information', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Fee Structure Title (e.g., B.Tech CSE Sem 1)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: 'ALL', child: Text('All Departments')),
                      ..._departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                    ],
                    onChanged: (val) => setState(() => _selectedDepartment = val),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSemester,
                    decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: 'ALL', child: Text('All Semesters')),
                      ...List.generate(8, (i) => DropdownMenuItem(value: '${i + 1}', child: Text('Semester ${i + 1}'))),
                    ],
                    onChanged: (val) => setState(() => _selectedSemester = val),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fee Components', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _addComponent(),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Component'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _componentControllers.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _componentControllers[index].nameController,
                        decoration: const InputDecoration(labelText: 'Component Name', border: InputBorder.none),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _componentControllers[index].amountController,
                        decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹', border: InputBorder.none),
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
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTotalCard() {
    return Card(
      elevation: 0,
      color: const Color(0xFF4F46E5).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF4F46E5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Structure Amount',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
            ),
            Text(
              '₹${_totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
            ),
          ],
        ),
      ),
    );
  }
}
