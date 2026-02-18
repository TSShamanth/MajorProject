import 'package:flutter/material.dart';
import 'package:flutter_application/models/exam_model.dart';
import 'package:flutter_application/models/room_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/models/invigilator_assignment.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';

class InvigilatorAssignmentScreen extends StatefulWidget {
  final String examId;

  const InvigilatorAssignmentScreen({super.key, required this.examId});

  @override
  InvigilatorAssignmentScreenState createState() => InvigilatorAssignmentScreenState();
}

class InvigilatorAssignmentScreenState extends State<InvigilatorAssignmentScreen> {
  final ApiService _apiService = ApiService();
  Exam? _exam;
  bool _isLoading = true;
  String? _errorMessage;
  List<Room> _rooms = [];
  List<UserModel> _faculty = [];
  List<InvigilatorAssignment> _assignments = [];

  // Map to store temporary selections for new assignments
  final Map<String, String?> _selectedFacultyForRoom = {}; // Key: Room ID, Value: Faculty UID

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) {
        if (mounted) setState(() => _isLoading = false);
        _errorMessage = 'Institution ID not found.';
        return;
      }

      final examFuture = _apiService.getExamById(institutionId, widget.examId);
      final roomsFuture = _apiService.getRooms(institutionId);
      // Assuming a method to get faculty users or filter all users by role 'faculty'
      final allUsersFuture = _apiService.getUsers(institutionId);
      final assignmentsFuture = _apiService.getInvigilatorAssignments(institutionId, widget.examId);

      final results = await Future.wait([examFuture, roomsFuture, allUsersFuture, assignmentsFuture]);

      final fetchedExam = results[0] as Exam;
      final fetchedRooms = results[1] as List<Room>;
      final fetchedUsers = results[2] as List<UserModel>;
      final fetchedAssignments = results[3] as List<InvigilatorAssignment>;

      if (mounted) {
        setState(() {
          _exam = fetchedExam;
          _rooms = fetchedRooms;
          _faculty = fetchedUsers.where((user) => user.role == 'faculty').toList();
          _assignments = fetchedAssignments;

          // Populate _selectedFacultyForRoom with existing assignments
          for (var assignment in _assignments) {
            _selectedFacultyForRoom[assignment.roomId] = assignment.facultyId;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _assignInvigilator(String roomId, String? facultyId) async {
    if (!mounted) return;
    if (facultyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a faculty member.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) return;

      // Check if an assignment for this room already exists
      final existingAssignment = _assignments.firstWhere(
        (assignment) => assignment.roomId == roomId,
        orElse: () => InvigilatorAssignment(
            id: '', examId: widget.examId, roomId: '', facultyId: '', institutionId: institutionId),
      );

      final newAssignment = InvigilatorAssignment(
        id: existingAssignment.id.isNotEmpty ? existingAssignment.id : '', // Pass empty string if new assignment
        examId: widget.examId,
        roomId: roomId,
        facultyId: facultyId,
        institutionId: institutionId,
        session: 'Default', // TODO: Implement session selection if needed
      );

      await _apiService.assignInvigilator(institutionId, widget.examId, newAssignment);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invigilator assigned successfully!')),
        );
      }
      _fetchData(); // Refresh data
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to assign invigilator: ${e.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAssignment(String assignmentId) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) return;

      await _apiService.deleteInvigilatorAssignment(institutionId, widget.examId, assignmentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment deleted successfully!')),
        );
      }
      _fetchData(); // Refresh data
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to delete assignment: ${e.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invigilator Assignment'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _exam == null
                  ? const Center(child: Text('Exam not found.'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
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
                              const SizedBox(height: 20),
                              if (_rooms.isEmpty)
                                const Text('No rooms found. Please add rooms in Room Management.'),
                              if (_faculty.isEmpty)
                                const Text('No faculty found. Please add faculty users.'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _rooms.length,
                            itemBuilder: (context, index) {
                              final room = _rooms[index];
                              final assignedInvigilator = _assignments.firstWhere(
                                (assignment) => assignment.roomId == room.id,
                                orElse: () => InvigilatorAssignment(
                                    id: '', examId: widget.examId, roomId: '', facultyId: '', institutionId: ''),
                              );
                              final currentSelection = _selectedFacultyForRoom[room.id] ?? (assignedInvigilator.facultyId.isNotEmpty ? assignedInvigilator.facultyId : null);

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Room: ${room.name} (Capacity: ${room.capacity})',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 10),
                                      DropdownButtonFormField<String>(
                                        value: currentSelection,
                                        decoration: const InputDecoration(
                                          labelText: 'Assign Faculty',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: [
                                          const DropdownMenuItem<String>(
                                            value: null,
                                            child: Text('Select Faculty'),
                                          ),
                                          ..._faculty.map((user) {
                                            return DropdownMenuItem<String>(
                                              value: user.uid,
                                              child: Text(user.displayName),
                                            );
                                          }),
                                        ],
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _selectedFacultyForRoom[room.id] = newValue;
                                            });
                                            _assignInvigilator(room.id, newValue);
                                          } else {
                                            setState(() {
                                              _selectedFacultyForRoom.remove(room.id);
                                            });
                                            // TODO: Option to unassign invigilator
                                            if (assignedInvigilator.id.isNotEmpty) {
                                              _deleteAssignment(assignedInvigilator.id);
                                            }
                                          }
                                        },
                                      ),
                                      if (assignedInvigilator.id.isNotEmpty && currentSelection != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text('Currently assigned: ${_faculty.firstWhere((f) => f.uid == currentSelection, orElse: () => UserModel(uid: '', email: '', displayName: '', role: '')).displayName}'),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}
