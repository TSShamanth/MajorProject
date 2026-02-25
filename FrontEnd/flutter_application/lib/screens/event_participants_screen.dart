import 'package:flutter/material.dart';
import '../services/event_service.dart';
import '../services/session_manager.dart';

class EventParticipantsScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventParticipantsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<EventParticipantsScreen> createState() => _EventParticipantsScreenState();
}

class _EventParticipantsScreenState extends State<EventParticipantsScreen> {
  late EventService _eventService;
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = true;
  String? _institutionId;

  @override
  void initState() {
    super.initState();
    _eventService = EventService();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final institutionId = await SessionManager.getInstitutionId();
    setState(() {
      _institutionId = institutionId;
    });
    if (_institutionId != null) {
      _fetchParticipants();
    }
  }

  Future<void> _fetchParticipants() async {
    try {
      final participants = await _eventService.getParticipants(_institutionId!, widget.eventId);
      setState(() {
        _participants = participants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _toggleAttendance(String studentId, bool currentStatus) async {
    // Optimistic UI update
    final index = _participants.indexWhere((p) => p['userId'] == studentId);
    if (index == -1) return;

    final newState = !currentStatus;
    setState(() {
      _participants[index]['status'] = newState ? 'ATTENDED' : 'REGISTERED';
    });

    try {
      await _eventService.markAttendance(_institutionId!, widget.eventId, studentId, newState);
    } catch (e) {
      // Revert on failure
      setState(() {
        _participants[index]['status'] = currentStatus ? 'ATTENDED' : 'REGISTERED';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update attendance')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Participants', style: TextStyle(fontSize: 16)),
            Text(widget.eventTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _participants.isEmpty
              ? const Center(child: Text('No registrations yet'))
              : ListView.builder(
                  itemCount: _participants.length,
                  itemBuilder: (context, index) {
                    final participant = _participants[index];
                    final isPresent = participant['status'] == 'ATTENDED';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPresent ? Colors.green : Colors.grey,
                          child: Text(
                            (participant['userName'] != null && participant['userName'].toString().isNotEmpty)
                                ? participant['userName'].toString()[0].toUpperCase()
                                : 'U',
                          ),
                        ),
                        title: Text(participant['userName'] ?? 'Unknown User'),
                        subtitle: Text(participant['userEmail'] ?? ''),
                        trailing: Switch(
                          value: isPresent,
                          activeColor: Colors.green,
                          onChanged: (val) => _toggleAttendance(participant['userId'], isPresent),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
