import 'package:flutter/material.dart';
import 'package:flutter_application/models/exam_model.dart';
import 'package:flutter_application/models/room_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/models/seating_entry.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';

class HallAllocationScreen extends StatefulWidget {
  final String examId;

  const HallAllocationScreen({super.key, required this.examId});

  @override
  HallAllocationScreenState createState() => HallAllocationScreenState();
}

class HallAllocationScreenState extends State<HallAllocationScreen> {
  final ApiService _apiService = ApiService();
  Exam? _exam;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, Room> _roomsMap = {};
  Map<String, UserModel> _usersMap = {};

  @override
  void initState() {
    super.initState();
    _fetchExamDetails();
  }

  Future<void> _fetchExamDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) {
        if (mounted) setState(() => _isLoading = false);
        _errorMessage = 'Institution ID not found.';
        return;
      }
      final exam = await _apiService.getExamById(institutionId, widget.examId);
      
      if (exam.seatingArrangement != null && exam.seatingArrangement!.isNotEmpty) {
        final List<Future> futures = [];
        futures.add(_apiService.getRooms(institutionId));
        futures.add(_apiService.getUsers(institutionId)); // Assuming this gets all users
        
        final results = await Future.wait(futures);
        final List<Room> fetchedRooms = results[0] as List<Room>;
        final List<UserModel> fetchedUsers = results[1] as List<UserModel>;

        _roomsMap = {for (var room in fetchedRooms) room.id: room};
        _usersMap = {for (var user in fetchedUsers) user.uid: user};
      }

      if (mounted) {
        setState(() {
          _exam = exam;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load exam details: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _allocateHalls() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) {
        if (mounted) setState(() => _isLoading = false);
        _errorMessage = 'Institution ID not found.';
        return;
      }

      await _apiService.allocateHalls(institutionId, widget.examId);
      
      // After allocation, refetch exam details to get the updated seating arrangement
      // and associated user/room details
      await _fetchExamDetails(); 

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Halls allocated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to allocate halls: ${e.toString()}';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group seating arrangements by room for display
    Map<String, List<SeatingEntry>> seatingByRoom = {};
    _exam?.seatingArrangement?.forEach((studentId, seatingEntry) {
      if (!seatingByRoom.containsKey(seatingEntry.roomId)) {
        seatingByRoom[seatingEntry.roomId] = [];
      }
      seatingByRoom[seatingEntry.roomId]!.add(seatingEntry);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hall Allocation'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _exam == null
                  ? const Center(child: Text('Exam not found.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exam: ${_exam!.name}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'Department: ${_exam!.departmentId}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Semester: ${_exam!.semester}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 20),
                          // ignore: unnecessary_null_comparison, unnecessary_non_null_assertion
                          (_exam!.frozenCandidateList == null || _exam!.frozenCandidateList!.isEmpty)
                              ? const Text('No students frozen for this exam. Please freeze eligible students first.')
                              : ElevatedButton(
                                  onPressed: _isLoading ? null : _allocateHalls,
                                  child: const Text('Allocate Halls'),
                                ),
                          const SizedBox(height: 20),
                          
                          // ignore: unnecessary_null_comparison, unnecessary_non_null_assertion
                          if (_exam!.seatingArrangement != null && _exam!.seatingArrangement!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Seating Arrangement:',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 10),
                                ...seatingByRoom.entries.map((entry) {
                                  final room = _roomsMap[entry.key];
                                  if (room == null) return const SizedBox.shrink();

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16.0),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Room: ${room.name} (Capacity: ${room.capacity})',
                                            style: Theme.of(context).textTheme.titleLarge,
                                          ),
                                          const Divider(),
                                          ...entry.value.map((seatingEntry) {
                                            final user = _usersMap[seatingEntry.studentId];
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    'Seat ${seatingEntry.seatNumber}: ',
                                                    style: Theme.of(context).textTheme.titleMedium,
                                                  ),
                                                  Text(
                                                    user?.displayName ?? seatingEntry.studentId,
                                                    style: Theme.of(context).textTheme.titleMedium,
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            )
                          // ignore: unnecessary_null_comparison, unnecessary_non_null_assertion
                          else if (_exam!.frozenCandidateList != null && _exam!.frozenCandidateList!.isNotEmpty)
                            const Text('Halls not yet allocated.'),
                        ],
                      ),
                    ),
    );
  }
}
