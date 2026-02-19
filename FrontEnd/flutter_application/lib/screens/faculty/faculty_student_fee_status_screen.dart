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
      return _apiService.getFacultyStudentFees(institutionId);
    }
    throw Exception('Institution ID not found');
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
                child: ListTile(
                  isThreeLine: true, // This will prevent the overflow error
                  title: Text(fee.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(fee.usn),
                  trailing: _buildStatusChip(fee),
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
