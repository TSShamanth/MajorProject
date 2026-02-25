import 'package:flutter/material.dart';
import 'package:flutter_application/models/payment_model.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/services/fee_service.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/models/fee_structure_model.dart';
import 'package:flutter_application/models/fee_category_model.dart';
import 'package:flutter_application/models/department_model.dart';
import 'package:flutter_application/models/student_fee_model.dart';
import 'package:flutter_application/widgets/admin_layout.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class FeeManagementDashboardScreen extends StatefulWidget {
  const FeeManagementDashboardScreen({super.key});

  @override
  State<FeeManagementDashboardScreen> createState() =>
      _FeeManagementDashboardScreenState();
}

class _FeeManagementDashboardScreenState
    extends State<FeeManagementDashboardScreen> with SingleTickerProviderStateMixin {
  final FeeService _feeService = FeeService();
  final ApiService _apiService = ApiService();
  
  List<FeeStructure> _feeStructures = [];
  List<FeeCategory> _feeCategories = [];
  List<Department> _departments = [];
  List<StudentFee> _studentFees = [];
  Map<String, dynamic> _stats = {};
  
  bool _isLoading = true;
  String? _institutionId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      _institutionId = await SessionManager.getInstitutionId();
      if (_institutionId != null) {
        final structures = await _feeService.getFeeStructures(_institutionId!);
        final categories = await _feeService.getFeeCategories(_institutionId!);
        final departments = await _apiService.getDepartments(_institutionId!);
        final studentFees = await _feeService.getStudentFees(_institutionId!);
        final stats = await _feeService.getFeeStats(_institutionId!);
        
        if (mounted) {
          setState(() {
            _feeStructures = structures;
            _feeCategories = categories;
            _departments = departments;
            _studentFees = studentFees;
            _stats = stats;
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading fee data: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToEditor({FeeStructure? structure}) async {
    if (_institutionId != null) {
      context.push('/$_institutionId/admin/fee-structure-editor', extra: structure);
    }
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Fee Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty && _institutionId != null) {
                await _feeService.createFeeCategory(_institutionId!, controller.text);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) {
                  _loadData();
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showGenerateFeeDialog() {
    String? selectedStructureId;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Generate Fees for Students'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select a fee structure to assign to applicable students.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStructureId,
                decoration: const InputDecoration(labelText: 'Fee Structure', border: OutlineInputBorder()),
                items: _feeStructures.map((s) => DropdownMenuItem(value: s.id, child: Text(s.title))).toList(),
                onChanged: (val) => setDialogState(() => selectedStructureId = val),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Due Date'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedStructureId == null
                  ? null
                  : () async {
                      if (_institutionId != null) {
                        await _feeService.generateFees(_institutionId!, selectedStructureId!, selectedDate);
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (mounted) _loadData();
                      }
                    },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  String _getDepartmentName(String departmentId) {
    if (departmentId == 'ALL') return 'All Departments';
    try {
      return _departments.firstWhere((d) => d.id == departmentId).name;
    } catch (e) {
      return 'Unknown Department';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Fee Management',
      breadcrumbs: const [
        Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        Text('Fee Management', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 13, fontWeight: FontWeight.bold)),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderActions(),
                  const SizedBox(height: 24),
                  _buildStatsGrid(),
                  const SizedBox(height: 32),
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF4F46E5),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF4F46E5),
                    tabs: const [
                      Tab(text: 'Fee Configuration'),
                      Tab(text: 'Student Fee Summary'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 600,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildConfigurationTab(),
                        _buildStudentFeesSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildConfigurationTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeeCategoriesSection(),
          const SizedBox(height: 32),
          _buildFeeStructuresSection(),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fee Management Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Text('Manage fee categories, structures and assignments', style: TextStyle(color: Colors.grey)),
          ],
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _showGenerateFeeDialog,
              icon: const Icon(Icons.bolt, color: Colors.white),
              label: const Text('Generate Fees'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _showAddCategoryDialog,
              icon: const Icon(Icons.category_outlined),
              label: const Text('Add Category'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4F46E5),
                side: const BorderSide(color: Color(0xFF4F46E5)),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  if (_institutionId != null) {
                    await _feeService.downloadFeeReport(_institutionId!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fee report downloaded successfully!')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error downloading fee report: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Download Report (CSV)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _navigateToEditor(),
              icon: const Icon(Icons.add),
              label: const Text('New Fee Structure'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.0,
      children: [
        StatCard(
          title: 'Total Collected',
          value: '₹${(_stats['totalCollected'] ?? 0.0).toStringAsFixed(0)}',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        StatCard(
          title: 'Total Pending',
          value: '₹${(_stats['totalPending'] ?? 0.0).toStringAsFixed(0)}',
          icon: Icons.error_outline,
          color: Colors.orange,
        ),
        StatCard(
          title: 'Overdue',
          value: '₹${(_stats['overdue'] ?? 0.0).toStringAsFixed(0)}',
          icon: Icons.dangerous_outlined,
          color: Colors.red,
        ),
        StatCard(
          title: 'Total Assignments',
          value: '${_stats['totalCount'] ?? 0}',
          icon: Icons.people_outline,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildFeeCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fee Categories', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text('${_feeCategories.length} Categories', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 16),
        _feeCategories.isEmpty
            ? const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No categories defined yet.')))
            : Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _feeCategories.map((category) {
                  return Chip(
                    label: Text(category.name),
                    onDeleted: () async {
                      if (_institutionId != null) {
                        await _feeService.deleteFeeCategory(_institutionId!, category.id);
                        if (mounted) {
                          _loadData();
                        }
                      }
                    },
                    backgroundColor: const Color(0xFFEEF2FF),
                    labelStyle: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildFeeStructuresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fee Structures', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text('${_feeStructures.length} Structures', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 16),
        _feeStructures.isEmpty
            ? const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No fee structures defined yet.')))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _feeStructures.length,
                itemBuilder: (_, index) {
                  final structure = _feeStructures[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(structure.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(
                        'Dept: ${_getDepartmentName(structure.departmentId)} • Sem: ${structure.semester}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${structure.totalAmount.toStringAsFixed(2)}', 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                              Text('${structure.components.length} Components', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            onPressed: () => _navigateToEditor(structure: structure),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              if (_institutionId != null) {
                                await _feeService.deleteFeeStructure(_institutionId!, structure.id);
                                if (mounted) {
                                  _loadData();
                                }
                              }
                            },
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

  Widget _buildStudentFeesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Student Fee Assignments', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text('${_studentFees.length} Records', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _studentFees.isEmpty
              ? const Center(child: Text('No fees assigned yet. Use "Generate Fees" to start.'))
              : ListView.builder(
                  itemCount: _studentFees.length,
                  itemBuilder: (context, index) {
                    final fee = _studentFees[index];
                    Color statusColor = Colors.red;
                    if (fee.status == 'PAID') statusColor = Colors.green;
                    if (fee.status == 'PARTIAL') statusColor = Colors.orange;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        isThreeLine: true, // Allocate more space for the trailing widget
                        title: Text(fee.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${fee.usn}\n${fee.feeStructureTitle}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${fee.balanceAmount.toStringAsFixed(0)} Due', 
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                if (fee.fineAmount > 0)
                                  Text('Fine: ₹${fee.fineAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 10)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text(fee.status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.history, color: Colors.blue),
                              tooltip: 'Payment History',
                              onPressed: () => _showPaymentHistoryDialog(fee),
                            ),
                            if (fee.balanceAmount > 0)
                              IconButton(
                                icon: const Icon(Icons.add_card),
                                tooltip: 'Record Payment',
                                onPressed: () => _showRecordPaymentDialog(fee),
                                color: Theme.of(context).primaryColor,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showPaymentHistoryDialog(StudentFee fee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment History - ${fee.studentName}'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: FutureBuilder<List<Payment>>(
            future: _feeService.getPaymentHistory(_institutionId!, fee.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No payments recorded yet.'));
              }
              final payments = snapshot.data!;
              return ListView.builder(
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final p = payments[index];
                  return ListTile(
                    title: Text('₹${p.amountPaid.toStringAsFixed(2)} - ${p.paymentMethod}'),
                    subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(p.paymentDate)),
                    trailing: IconButton(
                      icon: const Icon(Icons.download, color: Color(0xFF4F46E5)),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await _feeService.downloadReceipt(_institutionId!, p.id, p.receiptNumber);
                        } catch (e) {
                          messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(StudentFee fee) {
    final amountController = TextEditingController(text: fee.balanceAmount.toStringAsFixed(0));
    String selectedPaymentMethod = 'OFFLINE_CASH';
    final transactionIdController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Student: ${fee.studentName} (${fee.usn})', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Balance Due: ₹${fee.balanceAmount.toStringAsFixed(0)}'),
                const SizedBox(height: 20),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount Paid', border: OutlineInputBorder(), prefixText: '₹'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPaymentMethod,
                  decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'OFFLINE_CASH', child: Text('Offline (Cash)')),
                    DropdownMenuItem(value: 'OFFLINE_CHEQUE', child: Text('Offline (Cheque)')),
                    DropdownMenuItem(value: 'ONLINE', child: Text('Online')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedPaymentMethod = val!),
                ),
                if (selectedPaymentMethod == 'ONLINE') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: transactionIdController,
                    decoration: const InputDecoration(labelText: 'Transaction ID', border: OutlineInputBorder()),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0 || amount > fee.balanceAmount) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Invalid amount entered.')),
                    );
                  }
                  return;
                }
                
                try {
                  if (_institutionId != null) {
                    await _feeService.recordPayment(
                      _institutionId!,
                      fee.id,
                      amount,
                      selectedPaymentMethod,
                      transactionId: transactionIdController.text.isNotEmpty ? transactionIdController.text : null,
                      notes: notesController.text.isNotEmpty ? notesController.text : null,
                    );
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Payment recorded successfully!')),
                      );
                    }
                    if (mounted) {
                      _loadData();
                    }
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Error recording payment: $e')),
                    );
                  }
                }
              },
              child: const Text('Record'),
            ),
          ],
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
