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
  bool _isDarkMode = false;

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
        final futures = await Future.wait([
          _feeService.getFeeStructures(_institutionId!),
          _feeService.getFeeCategories(_institutionId!),
          _apiService.getDepartments(_institutionId!),
          _feeService.getStudentFees(_institutionId!),
          _feeService.getFeeStats(_institutionId!),
        ]);
        
        if (mounted) {
          setState(() {
            _feeStructures = futures[0] as List<FeeStructure>;
            _feeCategories = futures[1] as List<FeeCategory>;
            _departments = futures[2] as List<Department>;
            _studentFees = futures[3] as List<StudentFee>;
            _stats = futures[4] as Map<String, dynamic>;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading fee data: $e');
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
        backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        title: Text('Add Fee Category', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
          decoration: _inputDecoration('Category Name', Icons.category_rounded),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
            onPressed: () async {
              if (controller.text.isNotEmpty && _institutionId != null) {
                await _feeService.createFeeCategory(_institutionId!, controller.text);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                _loadData();
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
          backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          title: Text('Generate Fees', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Assign a structure to all applicable students.', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600])),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedStructureId,
                dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                decoration: _inputDecoration('Fee Structure', Icons.account_balance_wallet_rounded),
                items: _feeStructures.map((s) => DropdownMenuItem(value: s.id, child: Text(s.title))).toList(),
                onChanged: (val) => setDialogState(() => selectedStructureId = val),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Due Date', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87, fontSize: 14)),
                subtitle: Text(DateFormat('dd MMM yyyy').format(selectedDate), style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.calendar_today_rounded, color: Color(0xFF4F46E5)),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              onPressed: selectedStructureId == null ? null : () async {
                if (_institutionId != null) {
                  await _feeService.generateFees(_institutionId!, selectedStructureId!, selectedDate);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  _loadData();
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
      return 'General';
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: 'Fee Management',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Fee Management', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(textPrimary, textSecondary),
                  const SizedBox(height: 32),
                  _buildStatsGrid(),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB))),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF4F46E5),
                      unselectedLabelColor: textSecondary,
                      indicatorColor: const Color(0xFF4F46E5),
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'Configurations'),
                        Tab(text: 'Student Fee Records'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 800,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildConfigurationTab(textPrimary, textSecondary),
                        _buildStudentFeesSection(textPrimary, textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financial Oversight', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('Manage categories, fee structures, and collection tracking', style: TextStyle(fontSize: 14, color: textSecondary)),
          ],
        ),
        Wrap(
          spacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: _showGenerateFeeDialog,
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: const Text('Generate Fees'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
            ElevatedButton.icon(
              onPressed: () => _navigateToEditor(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New Structure'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 2.5,
          children: [
            _buildStatCard('Collected', '₹${(_stats['totalCollected'] ?? 0.0).toStringAsFixed(0)}', Icons.check_circle_rounded, const Color(0xFF10B981)),
            _buildStatCard('Pending', '₹${(_stats['totalPending'] ?? 0.0).toStringAsFixed(0)}', Icons.pending_rounded, const Color(0xFFF59E0B)),
            _buildStatCard('Overdue', '₹${(_stats['overdue'] ?? 0.0).toStringAsFixed(0)}', Icons.warning_rounded, const Color(0xFFEF4444)),
            _buildStatCard('Total Records', '${_stats['totalCount'] ?? 0}', Icons.people_rounded, const Color(0xFF4F46E5)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937))),
                Text(title, style: TextStyle(fontSize: 13, color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationTab(Color textPrimary, Color textSecondary) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategorySection(textPrimary, textSecondary),
          const SizedBox(height: 32),
          _buildStructureSection(textPrimary, textSecondary),
        ],
      ),
    );
  }

  Widget _buildCategorySection(Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fee Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
            IconButton(onPressed: _showAddCategoryDialog, icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF4F46E5))),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _feeCategories.map((c) => Chip(
            label: Text(c.name),
            backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
            labelStyle: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
            onDeleted: () async {
              if (_institutionId != null) {
                await _feeService.deleteFeeCategory(_institutionId!, c.id);
                _loadData();
              }
            },
            deleteIconColor: const Color(0xFF4F46E5).withOpacity(0.5),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildStructureSection(Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Available Fee Structures', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
        const SizedBox(height: 16),
        ..._feeStructures.map((s) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.description_rounded, color: Color(0xFF4F46E5), size: 20)),
            title: Text(s.title, style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
            subtitle: Text('Dept: ${_getDepartmentName(s.departmentId)} • Sem: ${s.semester}', style: TextStyle(fontSize: 12, color: textSecondary)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('₹${s.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 16)),
                const SizedBox(width: 16),
                IconButton(icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20), onPressed: () => _navigateToEditor(structure: s)),
                IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () async {
                  if (_institutionId != null) {
                    await _feeService.deleteFeeStructure(_institutionId!, s.id);
                    _loadData();
                  }
                }),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildStudentFeesSection(Color textPrimary, Color textSecondary) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Collection Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
            TextButton.icon(
              onPressed: () {}, // Download report
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Export Records'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _studentFees.length,
            itemBuilder: (context, index) {
              final fee = _studentFees[index];
              Color statusColor = fee.status == 'PAID' ? const Color(0xFF10B981) : (fee.status == 'PARTIAL' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text(fee.studentName, style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                  subtitle: Text('${fee.usn} • ${fee.feeStructureTitle}', style: TextStyle(fontSize: 12, color: textSecondary)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${fee.balanceAmount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(fee.status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(icon: const Icon(Icons.history_rounded, color: Colors.blue, size: 20), onPressed: () => _showPaymentHistoryDialog(fee)),
                      if (fee.balanceAmount > 0)
                        IconButton(icon: const Icon(Icons.add_card_rounded, color: Color(0xFF4F46E5), size: 20), onPressed: () => _showRecordPaymentDialog(fee)),
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
        backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        title: Text('Payment History - ${fee.studentName}', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)),
        content: SizedBox(
          width: 500,
          height: 400,
          child: FutureBuilder<List<Payment>>(
            future: _feeService.getPaymentHistory(_institutionId!, fee.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('No payments recorded yet.', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600])));
              final payments = snapshot.data!;
              return ListView.separated(
                itemCount: payments.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final p = payments[index];
                  return ListTile(
                    title: Text('₹${p.amountPaid.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black87)),
                    subtitle: Text('${p.paymentMethod} • ${DateFormat('dd MMM yyyy, hh:mm a').format(p.paymentDate)}', style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600])),
                    trailing: IconButton(icon: const Icon(Icons.download_rounded, color: Color(0xFF4F46E5)), onPressed: () => _feeService.downloadReceipt(_institutionId!, p.id, p.receiptNumber)),
                  );
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showRecordPaymentDialog(StudentFee fee) {
    final amountController = TextEditingController(text: fee.balanceAmount.toStringAsFixed(0));
    String selectedPaymentMethod = 'OFFLINE_CASH';
    final transactionIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          title: Text('Record Payment', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${fee.studentName} (${fee.usn})', style: TextStyle(fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black87)),
                Text('Balance Due: ₹${fee.balanceAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: amountController,
                  style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                  decoration: _inputDecoration('Amount Paid', Icons.payments_rounded),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPaymentMethod,
                  dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                  style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                  decoration: _inputDecoration('Payment Method', Icons.account_balance_rounded),
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
                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                    decoration: _inputDecoration('Transaction ID', Icons.vpn_key_rounded),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) return;
                if (_institutionId != null) {
                  await _feeService.recordPayment(_institutionId!, fee.id, amount, selectedPaymentMethod, transactionId: transactionIdController.text.isNotEmpty ? transactionIdController.text : null);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  _loadData();
                }
              },
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF4F46E5).withOpacity(0.7), size: 20),
      filled: true,
      fillColor: _isDarkMode ? const Color(0xFF111827).withOpacity(0.5) : Colors.grey[50]!,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
