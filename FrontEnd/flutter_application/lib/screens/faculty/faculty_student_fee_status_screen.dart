import 'package:flutter/material.dart';
import 'package:flutter_application/models/student_fee_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:intl/intl.dart';

class FacultyStudentFeeStatusScreen extends StatefulWidget {
  const FacultyStudentFeeStatusScreen({super.key});

  @override
  State<FacultyStudentFeeStatusScreen> createState() => _FacultyStudentFeeStatusScreenState();
}

class _FacultyStudentFeeStatusScreenState extends State<FacultyStudentFeeStatusScreen> {
  late Future<List<StudentFee>> _studentFeesFuture;
  final ApiService _apiService = ApiService();

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
        title: const Text('Add/Edit Remarks'),
        content: TextField(
          controller: remarksController,
          decoration: const InputDecoration(labelText: 'Remarks', border: OutlineInputBorder()),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _notifyDefaulters(StudentFee fee) {
    // In a real application, this would trigger a notification service (email, in-app, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification sent to ${fee.studentName} regarding outstanding fees.')),
    );
    // You might also want to log this action or update a 'last_notified' timestamp
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Students' Fee Status"),
      ),
      body: FutureBuilder<List<StudentFee>>(
        future: _studentFeesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No students assigned or no fee data available.'));
          }

          final studentFees = snapshot.data!;
          return ListView.builder(
            itemCount: studentFees.length,
            itemBuilder: (context, index) {
              final fee = studentFees[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text(fee.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(fee.usn),
                  trailing: _buildStatusChip(fee),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fee Structure: ${fee.feeStructureTitle}'),
                          Text('Total Amount: ₹${NumberFormat.decimalPattern().format(fee.totalAmount)}'),
                          Text('Paid Amount: ₹${NumberFormat.decimalPattern().format(fee.paidAmount)}'),
                          Text('Balance Due: ₹${NumberFormat.decimalPattern().format(fee.balanceAmount)}'),
                          if (fee.dueDate != null)
                            Text('Due Date: ${DateFormat('dd MMM, yyyy').format(fee.dueDate!)}'),
                          const SizedBox(height: 8),
                          Text('Remarks: ${fee.facultyRemarks ?? 'N/A'}', style: const TextStyle(fontStyle: FontStyle.italic)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.comment),
                                label: const Text('Add Remarks'),
                                onPressed: () => _showAddRemarksDialog(fee),
                              ),
                              if (fee.balanceAmount > 0) // Only show notify for defaulters
                                TextButton.icon(
                                  icon: const Icon(Icons.notifications_active, color: Colors.orange),
                                  label: const Text('Notify Defaulter'),
                                  onPressed: () => _notifyDefaulters(fee),
                                ),
                              // Add 'Recommend Exam Block' here in Phase 4
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            statusText,
            style: TextStyle(color: chipColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
