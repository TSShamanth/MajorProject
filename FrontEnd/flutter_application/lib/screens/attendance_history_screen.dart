import 'package:flutter/material.dart';
import 'package:flutter_application/models/attendance_log_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:go_router/go_router.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final ApiService _apiService = ApiService();
  String? _institutionId;
  List<AttendanceLog> _history = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Getting the context here can be problematic in initState.
    // Let's move the logic to a safer place.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getInstitutionIdAndFetchHistory();
    });
  }

  Future<void> _getInstitutionIdAndFetchHistory() async {
    // It's safer to get the GoRouter from the context here,
    // after the first frame has been built.
    if (!mounted) return;
    final router = GoRouter.of(context);
    final routeState = router.routerDelegate.currentConfiguration;
    final pathParams = routeState.pathParameters;
    _institutionId = pathParams['institutionId'];

    if (_institutionId == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Institution ID not found.';
          _isLoading = false;
        });
      }
      return;
    }

    await _fetchAttendanceHistory();
  }

  Future<void> _fetchAttendanceHistory() async {
    if (_institutionId == null) return;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final history = await _apiService.getAttendanceHistory(_institutionId!);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load history: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clock-in History'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAttendanceHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_errorMessage!),
                    ),
                  )
                : _history.isEmpty
                    ? const Center(child: Text('No attendance records found.'))
                    : ListView.builder(
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
                      ),
      ),
    );
  }
}
