import 'package:flutter/material.dart';
import 'package:flutter_application/models/leave_application_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:intl/intl.dart';

class LeaveHistoryScreen extends StatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  late Future<List<LeaveApplication>> _leaveHistoryFuture;
  List<LeaveApplication> _allLeaves = [];
  List<LeaveApplication> _pendingLeaves = [];
  List<LeaveApplication> _approvedLeaves = [];
  List<LeaveApplication> _rejectedLeaves = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _leaveHistoryFuture = _apiService.getLeaveHistory();
    _leaveHistoryFuture.then((leaves) {
      setState(() {
        _allLeaves = leaves;
        _pendingLeaves = leaves.where((leave) => leave.status == 'Pending').toList();
        _approvedLeaves = leaves.where((leave) => leave.status == 'Approved').toList();
        _rejectedLeaves = leaves.where((leave) => leave.status == 'Rejected').toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Pending'),
                Tab(text: 'Approved'),
                Tab(text: 'Rejected'),
              ],
              labelColor: const Color(0xFF4F46E5),
              unselectedLabelColor: const Color(0xFF64748B),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<LeaveApplication>>(
              future: _leaveHistoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No leave history found.'));
                } else {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLeaveList(_allLeaves),
                      _buildLeaveList(_pendingLeaves),
                      _buildLeaveList(_approvedLeaves),
                      _buildLeaveList(_rejectedLeaves),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveList(List<LeaveApplication> leaves) {
    if (leaves.isEmpty) {
      return const Center(child: Text('No leaves in this category.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: leaves.length,
      itemBuilder: (context, index) {
        final leave = leaves[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      leave.leaveType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    _buildStatusChip(leave.status),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  '${DateFormat.yMMMd().format(leave.startDate)} - ${DateFormat.yMMMd().format(leave.endDate)}',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(leave.reason),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16.0, color: Colors.grey),
                    const SizedBox(width: 4.0),
                    Text('Approved by: ${leave.professor}'),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    switch (status) {
      case 'Approved':
        color = Colors.green;
        text = 'Approved';
        break;
      case 'Pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'Rejected':
        color = Colors.red;
        text = 'Rejected';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }
    return Chip(
      label: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }
}