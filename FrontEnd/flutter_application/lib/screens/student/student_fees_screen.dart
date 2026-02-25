import 'package:flutter/material.dart';
import 'package:flutter_application/models/student_fee_model.dart';
import 'package:flutter_application/services/fee_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
    return Scaffold(
      // The AppBar is now removed. StudentShell will provide the AppBar.
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _studentFees.isEmpty
              ? const Center(child: Text('No fee assignments found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _studentFees.length,
                  itemBuilder: (context, index) {
                    final fee = _studentFees[index];
                    return _buildFeeCard(fee);
                  },
                ),
    );
  }

  Widget _buildFeeCard(StudentFee fee) {
    Color statusColor;
    String statusText;

    switch (fee.status) {
      case 'PAID':
        statusColor = Colors.green;
        statusText = 'Paid in Full';
        break;
      case 'PARTIAL':
        statusColor = Colors.orange;
        statusText = 'Partially Paid';
        break;
      default:
        statusColor = Colors.red;
        statusText = 'Payment Due';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (_institutionId != null) {
            context.push('/$_institutionId/student/fees/${fee.id}', extra: fee);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      fee.feeStructureTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatColumn('Balance Due', '₹${NumberFormat.decimalPattern().format(fee.balanceAmount)}', color: fee.balanceAmount > 0 ? Colors.red : Colors.green),
                  if(fee.dueDate != null)
                    Text('Due: ${DateFormat('dd MMM, yyyy').format(fee.dueDate!)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
