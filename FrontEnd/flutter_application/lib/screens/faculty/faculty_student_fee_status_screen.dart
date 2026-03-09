import 'package:flutter/material.dart';
import 'package:flutter_application/models/student_fee_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:intl/intl.dart';
import '../../widgets/faculty_layout.dart';

class FacultyStudentFeeStatusScreen extends StatefulWidget {
  const FacultyStudentFeeStatusScreen({super.key});

  @override
  State<FacultyStudentFeeStatusScreen> createState() => _FacultyStudentFeeStatusScreenState();
}

class _FacultyStudentFeeStatusScreenState extends State<FacultyStudentFeeStatusScreen> {
  late Future<List<StudentFee>> _studentFeesFuture;
  final ApiService _apiService = ApiService();
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _studentFeesFuture = _fetchStudentFees();
  }

  Future<List<StudentFee>> _fetchStudentFees() async {
    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId != null) {
      return _apiService.getStudentFeesForFaculty(institutionId);
    }
    throw Exception('Institution ID not found');
  }

  Future<void> _refreshFees() async {
    setState(() {
      _studentFeesFuture = _fetchStudentFees();
    });
  }

  void _showAddRemarksDialog(StudentFee fee) {
    final remarksController = TextEditingController(text: fee.facultyRemarks);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        title: Text('Add/Edit Remarks', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
        content: TextField(
          controller: remarksController,
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: 'Remarks',
            labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final institutionId = await SessionManager.getInstitutionId();
                if (institutionId != null) {
                  await _apiService.updateStudentFeeRemarks(institutionId, fee.id, remarksController.text);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  _refreshFees();
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Error updating remarks: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _notifyDefaulters(StudentFee fee) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification sent to ${fee.studentName} regarding outstanding fees.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF4F46E5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);

    return FacultyLayout(
      title: 'Fee Management',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Students\' Fees', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Fee Records',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitor and follow up on fee payments for your mentees',
                      style: TextStyle(fontSize: 14, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _refreshFees,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Sync Records'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<StudentFee>>(
                future: _studentFeesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final studentFees = snapshot.data!;
                  return ListView.builder(
                    itemCount: studentFees.length,
                    itemBuilder: (context, index) {
                      final fee = studentFees[index];
                      return _buildFeeCard(fee);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined, size: 64, color: _isDarkMode ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'No Fee Records Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'No students assigned or no fee data available for your mentees.',
            style: TextStyle(color: _isDarkMode ? Colors.grey[500] : Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
          const SizedBox(height: 20),
          Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center, style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600])),
          const SizedBox(height: 16),
          TextButton(onPressed: _refreshFees, child: const Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildFeeCard(StudentFee fee) {
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFF4F46E5),
          collapsedIconColor: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    fee.studentName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fee.studentName,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937)),
                    ),
                    Text(
                      fee.usn,
                      style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: _buildStatusChip(fee),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildDetailRow('Fee Structure', fee.feeStructureTitle),
                  _buildDetailRow('Total Amount', '₹${NumberFormat.decimalPattern().format(fee.totalAmount)}'),
                  _buildDetailRow('Paid Amount', '₹${NumberFormat.decimalPattern().format(fee.paidAmount)}', valueColor: Colors.green),
                  _buildDetailRow('Balance Due', '₹${NumberFormat.decimalPattern().format(fee.balanceAmount)}', valueColor: fee.balanceAmount > 0 ? Colors.red : Colors.green),
                  if (fee.dueDate != null)
                    _buildDetailRow('Due Date', DateFormat('dd MMM, yyyy').format(fee.dueDate!)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notes_rounded, size: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text('Faculty Remarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _isDarkMode ? Colors.grey[300] : Colors.grey[700])),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          fee.facultyRemarks ?? 'No remarks added yet.',
                          style: TextStyle(fontSize: 13, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontStyle: fee.facultyRemarks == null ? FontStyle.italic : FontStyle.normal),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.comment_outlined, size: 18),
                        label: const Text('Add Remarks'),
                        onPressed: () => _showAddRemarksDialog(fee),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4F46E5),
                          side: const BorderSide(color: Color(0xFF4F46E5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      if (fee.balanceAmount > 0) ...[
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.notifications_active_outlined, size: 18),
                          label: const Text('Notify Defaulter'),
                          onPressed: () => _notifyDefaulters(fee),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.withOpacity(0.1),
                            foregroundColor: Colors.orange,
                            elevation: 0,
                            side: const BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: valueColor ?? (_isDarkMode ? Colors.white : Colors.black))),
        ],
      ),
    );
  }

  Widget _buildStatusChip(StudentFee fee) {
    Color chipColor;
    String statusText;

    if (fee.status == 'PAID') {
      chipColor = Colors.green;
      statusText = 'PAID';
    } else if (fee.balanceAmount > 0 && fee.dueDate != null && fee.dueDate!.isBefore(DateTime.now())) {
      chipColor = Colors.red;
      statusText = 'OVERDUE';
    } else if (fee.status == 'PARTIAL') {
      chipColor = Colors.orange;
      statusText = 'PARTIAL';
    } else {
      chipColor = Colors.blueGrey;
      statusText = 'UNPAID';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '₹${NumberFormat.decimalPattern().format(fee.balanceAmount)} Due',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: fee.balanceAmount > 0 ? Colors.red : Colors.green),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: chipColor.withOpacity(0.3)),
          ),
          child: Text(
            statusText,
            style: TextStyle(color: chipColor, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
