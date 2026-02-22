import 'package:flutter/material.dart';
import 'package:flutter_application/models/attendance_log_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:go_router/go_router.dart';

class AdminAttendanceDashboardScreen extends StatefulWidget {
  const AdminAttendanceDashboardScreen({super.key});

  @override
  State<AdminAttendanceDashboardScreen> createState() =>
      _AdminAttendanceDashboardScreenState();
}

class _AdminAttendanceDashboardScreenState
    extends State<AdminAttendanceDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  String? _institutionId;
  List<UserModel> _facultyList = [];
  UserModel? _selectedFaculty;
  List<AttendanceLog> _history = [];

  bool _isLoadingFaculty = true;
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _institutionId = GoRouter.of(context)
          .routerDelegate
          .currentConfiguration
          .pathParameters['institutionId'];
      _fetchFaculty();
    });
  }

  Future<void> _fetchFaculty() async {
    if (_institutionId == null) return;
    try {
      final users = await _apiService.getUsers(_institutionId!);
      final faculty = users.where((user) => user.role == 'faculty').toList();
      if (mounted) {
        setState(() {
          _facultyList = faculty;
          _isLoadingFaculty = false;
        });
      }
    } catch (e) {
      // handle error
    }
  }

  Future<void> _fetchHistoryForFaculty(String facultyId) async {
    if (_institutionId == null) return;
    setState(() {
      _isLoadingHistory = true;
    });
    try {
      final history = await _apiService.getAttendanceHistoryForFaculty(
          _institutionId!, facultyId);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      // handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Attendance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Live Status'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoadingFaculty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLiveStatusTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildLiveStatusTab() {
    return ListView.builder(
      itemCount: _facultyList.length,
      itemBuilder: (context, index) {
        final faculty = _facultyList[index];
        final bool isClockedIn = faculty.attendanceStatus == 'Clocked-in';
        final Color statusColor = isClockedIn ? Colors.green : Colors.grey;
        return ListTile(
          title: Text(faculty.displayName),
          trailing: Chip(
            label: Text(faculty.attendanceStatus ?? 'Unknown'),
            backgroundColor: statusColor.withOpacity(0.2),
            side: BorderSide(color: statusColor),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField<UserModel>(
            value: _selectedFaculty,
            hint: const Text('Select a Faculty Member'),
            onChanged: (UserModel? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedFaculty = newValue;
                });
                _fetchHistoryForFaculty(newValue.uid);
              }
            },
            items: _facultyList.map((UserModel user) {
              return DropdownMenuItem<UserModel>(
                value: user,
                child: Text(user.displayName),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : _selectedFaculty == null
                  ? const Center(child: Text('Please select a faculty member to see their history.'))
                  : _history.isEmpty
                      ? const Center(child: Text('No history found for this faculty.'))
                      : _buildHistoryList(),
        )
      ],
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final log = _history[index];
        final bool isOnCampus = log.locationStatus == 'On-Campus';
        final Color cardColor = isOnCampus 
            ? Colors.green.shade50 
            : Colors.red.shade50;
        final Color borderColor = isOnCampus
            ? Colors.green.shade300
            : Colors.red.shade300;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          elevation: 1,
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: borderColor, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.formattedDate,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Clock-in: ${log.formattedClockInTime}'),
                    Text('Clock-out: ${log.formattedClockOutTime}'),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Expanded(
                       child: Row(
                         children: [
                           Icon(isOnCampus ? Icons.check_circle : Icons.warning, color: borderColor, size: 16,),
                           const SizedBox(width: 4),
                           Expanded(
                             child: Text(
                              log.locationDetail ?? 'N/A',
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                              overflow: TextOverflow.ellipsis,
                             ),
                           ),
                         ],
                       ),
                     ),
                    Text('Duration: ${log.formattedDuration}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
