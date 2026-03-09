import 'package:flutter/material.dart';
import 'package:flutter_application/models/payment_model.dart';
import 'package:flutter_application/models/student_fee_model.dart';
import 'package:flutter_application/services/fee_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/widgets/payment_bottom_sheet.dart';
import 'package:intl/intl.dart';
import '../../widgets/student_layout.dart';

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
    return StudentLayout(
      title: 'Fee Details',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Fees', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Details', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderInfo(),
                const SizedBox(height: 24),
                _buildSummaryGrid(),
                const SizedBox(height: 32),
                _buildSectionTitle('Fee Components'),
                _buildComponentsList(),
                const SizedBox(height: 32),
                _buildSectionTitle('Payment History'),
                _buildPaymentHistoryList(),
              ],
            ),
          ),
          if (widget.fee.balanceAmount > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildPaymentButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.fee.feeStructureTitle,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        if (widget.fee.dueDate != null)
          Text(
            'Payment due by ${DateFormat('dd MMMM, yyyy').format(widget.fee.dueDate!)}',
            style: const TextStyle(fontSize: 14, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
          ),
      ],
    );
  }

  Widget _buildSummaryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            _buildStatCard('Total Amount', widget.fee.totalAmount, const Color(0xFF1F2937), Icons.account_balance_wallet_rounded),
            _buildStatCard('Amount Paid', widget.fee.paidAmount, const Color(0xFF10B981), Icons.check_circle_rounded),
            _buildStatCard('Balance Due', widget.fee.balanceAmount, const Color(0xFFEF4444), Icons.error_rounded, isBold: true),
            _buildStatCard('Fines Applied', widget.fee.fineAmount, const Color(0xFFF59E0B), Icons.warning_rounded),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, double amount, Color color, IconData icon, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(
                  '₹${NumberFormat.decimalPattern().format(amount)}',
                  style: TextStyle(fontSize: 18, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5),
      ),
    );
  }
  
  Widget _buildComponentsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.fee.components.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 20, endIndent: 20),
        itemBuilder: (context, index) {
          final component = widget.fee.components[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            title: Text(component.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
            trailing: Text(
              '₹${NumberFormat.decimalPattern().format(component.amount)}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937), fontSize: 15),
            ),
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
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red))),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Icon(Icons.history_rounded, size: 40, color: Colors.grey[300]),
                const SizedBox(height: 12),
                const Text('No previous payments found.', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }
        final payments = snapshot.data!;
        return Column(
          children: payments.map((payment) => _buildPaymentHistoryCard(payment)).toList(),
        );
      },
    );
  }

  Widget _buildPaymentHistoryCard(Payment payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 20),
        ),
        title: Text(
          'Paid ₹${NumberFormat.decimalPattern().format(payment.amountPaid)}',
          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${DateFormat('dd MMM yyyy, hh:mm a').format(payment.paymentDate)} • ${payment.paymentMethod}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text('Receipt: #${payment.receiptNumber}', style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.file_download_outlined, color: Color(0xFF4F46E5)),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              if (_institutionId != null) {
                await _feeService.downloadReceipt(_institutionId!, payment.id, payment.receiptNumber);
              }
            } catch (e) {
              messenger.showSnackBar(SnackBar(content: Text('Error downloading receipt: $e')));
            }
          },
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.payment_rounded),
        label: Text('Pay ₹${NumberFormat.decimalPattern().format(widget.fee.balanceAmount)} Now'),
        onPressed: () => _showPaymentDialog(context, widget.fee),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, StudentFee fee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentBottomSheet(
        fee: fee,
        onPaymentSuccess: () {
          Navigator.of(context).pop();
          _loadPaymentHistory();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment successful!'), backgroundColor: Colors.green),
          );
        },
      ),
    );
  }
}
