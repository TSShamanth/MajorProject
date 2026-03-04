import 'package:flutter/material.dart';
import 'package:flutter_application/models/student_fee_model.dart';
import 'package:flutter_application/services/fee_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../widgets/student_layout.dart';

class StudentFeesScreen extends StatefulWidget {
  const StudentFeesScreen({super.key});

  @override
  State<StudentFeesScreen> createState() => _StudentFeesScreenState();
}

class _StudentFeesScreenState extends State<StudentFeesScreen> {
  final FeeService _feeService = FeeService();
  List<StudentFee> _studentFees = [];
  bool _isLoading = true;
  String? _institutionId;
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _institutionId = await SessionManager.getInstitutionId();
      _studentId = FirebaseAuth.instance.currentUser?.uid;
      if (_institutionId != null && _studentId != null) {
        final fees = await _feeService.getStudentFees(_institutionId!, studentId: _studentId);
        if (mounted) {
          setState(() {
            _studentFees = fees;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading student fees: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: 'Fee Management',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Fees', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF4F46E5),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _studentFees.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: _studentFees.map((fee) => _buildFeeCard(fee)).toList(),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Financial Overview',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Track your fee payments, dues, and transaction history',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.05), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF4F46E5), size: 64),
            ),
            const SizedBox(height: 24),
            const Text('No fee records found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            Text('There are currently no fee assignments linked to your profile.', 
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeCard(StudentFee fee) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (fee.status) {
      case 'PAID':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Paid in Full';
        break;
      case 'PARTIAL':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.pending_rounded;
        statusText = 'Partially Paid';
        break;
      default:
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.error_rounded;
        statusText = 'Payment Due';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_institutionId != null) {
              context.push('/$_institutionId/student/fees/${fee.id}', extra: fee);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fee.feeStructureTitle,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.3),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            statusText.toUpperCase(),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAmountInfo('Total Amount', fee.totalAmount, const Color(0xFF1F2937)),
                    _buildAmountInfo('Paid Amount', fee.paidAmount, const Color(0xFF10B981)),
                    _buildAmountInfo('Balance Due', fee.balanceAmount, fee.balanceAmount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981), isBold: true),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if(fee.dueDate != null)
                      Row(
                        children: [
                          const Icon(Icons.event_note_rounded, size: 16, color: Color(0xFF6B7280)),
                          const SizedBox(width: 8),
                          Text('Due on ${DateFormat('dd MMM, yyyy').format(fee.dueDate!)}', 
                            style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    const Spacer(),
                    const Text('View Details', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF4F46E5)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInfo(String label, double amount, Color color, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(
          '₹${NumberFormat.decimalPattern().format(amount)}',
          style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
