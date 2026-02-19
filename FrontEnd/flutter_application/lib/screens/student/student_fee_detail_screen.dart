import 'package:flutter/material.dart';
import 'package:flutter_application/models/payment_model.dart';
import 'package:flutter_application/models/student_fee_model.dart';
import 'package:flutter_application/services/fee_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:intl/intl.dart';

class StudentFeeDetailScreen extends StatefulWidget {
  final StudentFee fee;
  const StudentFeeDetailScreen({super.key, required this.fee});

  @override
  State<StudentFeeDetailScreen> createState() => _StudentFeeDetailScreenState();
}

class _StudentFeeDetailScreenState extends State<StudentFeeDetailScreen> {
  final FeeService _feeService = FeeService();
  late Future<List<Payment>> _paymentHistoryFuture;
  String? _institutionId;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  void _loadPaymentHistory() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (_institutionId != null) {
      setState(() {
        _paymentHistoryFuture = _feeService.getPaymentHistory(_institutionId!, widget.fee.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // The Scaffold and AppBar are now handled by the shell. This widget only returns the content.
    return Scaffold(
      backgroundColor: Colors.transparent, // Make scaffold transparent to show shell's background
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('Fee Components'),
            _buildComponentsList(),
            const SizedBox(height: 24),
            _buildSectionTitle('Payment History'),
            _buildPaymentHistoryList(),
          ],
        ),
      ),
      bottomNavigationBar: widget.fee.balanceAmount > 0 ? _buildPaymentButton() : null,
    );
  }

  Widget _buildSummaryCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Total Amount', '₹${NumberFormat.decimalPattern().format(widget.fee.totalAmount)}'),
                _buildStatColumn('Fine Applied', '₹${NumberFormat.decimalPattern().format(widget.fee.fineAmount)}', color: Colors.orange),
                _buildStatColumn('Amount Paid', '₹${NumberFormat.decimalPattern().format(widget.fee.paidAmount)}', color: Colors.green),
                _buildStatColumn('Balance Due', '₹${NumberFormat.decimalPattern().format(widget.fee.balanceAmount)}', color: Colors.red),
              ],
            ),
             if (widget.fee.dueDate != null) ...[
                const Divider(height: 28),
                Center(
                  child: Text(
                    'Due Date: ${DateFormat('dd MMM, yyyy').format(widget.fee.dueDate!)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
             ]
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
  
  Widget _buildComponentsList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.fee.components.length,
        itemBuilder: (context, index) {
          final component = widget.fee.components[index];
          return ListTile(
            title: Text(component.name),
            trailing: Text('₹${NumberFormat.decimalPattern().format(component.amount)}'),
            tileColor: index.isEven ? Colors.transparent : Theme.of(context).colorScheme.surface.withOpacity(0.03),
          );
        },
      ),
    );
  }

  Widget _buildPaymentHistoryList() {
    return FutureBuilder<List<Payment>>(
      future: _paymentHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: Text('No payment history found.')),
            ),
          );
        }
        final payments = snapshot.data!;
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return ListTile(
                tileColor: index.isEven ? Colors.transparent : Theme.of(context).colorScheme.surface.withOpacity(0.03),
                title: Text('Paid ₹${NumberFormat.decimalPattern().format(payment.amountPaid)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('on ${DateFormat('dd MMM, yyyy, hh:mm a').format(payment.paymentDate)} via ${payment.paymentMethod}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Receipt', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text('#${payment.receiptNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.download, size: 20, color: Color(0xFF4F46E5)),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          if (_institutionId != null) {
                            await _feeService.downloadReceipt(_institutionId!, payment.id, payment.receiptNumber);
                          }
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Error downloading receipt: $e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPaymentButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.payment),
        label: Text('Pay ₹${NumberFormat.decimalPattern().format(widget.fee.balanceAmount)} Now'),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Online Payment Gateway (Mock)')),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
