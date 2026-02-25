import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final EventModel? event;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.event,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late ApiService _apiService;
  late EventService _eventService;
  EventModel? _event;
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isRegistering = false;
  String? _institutionId;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _eventService = EventService();
    _event = widget.event;
    _initializeData();
  }

  Future<void> _initializeData() async {
    final institutionId = await SessionManager.getInstitutionId();
    setState(() {
      _institutionId = institutionId;
    });

    if (_institutionId != null) {
      await _fetchCurrentUser();
      if (_event == null) {
        _fetchEvent();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchEvent() async {
    try {
      final event = await _eventService.getEventById(_institutionId!, widget.eventId);
      setState(() {
        _event = event;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching event: $e');
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final user = await _apiService.getMe(_institutionId!);
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      debugPrint('Error fetching current user: $e');
    }
  }

  Future<void> _handleRegistration() async {
    if (_institutionId == null || _event == null) return;
    
    setState(() => _isRegistering = true);
    
    try {
      await _eventService.registerForEvent(_institutionId!, _event!.id);
      if (mounted) {
        setState(() => _isRegistering = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchEvent(); // Refresh event data to show updated participant count
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegistering = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    try {
      await _eventService.updateEventStatus(_institutionId!, _event!.id, status);
      if (mounted) {
        setState(() {
          _event = _event!.copyWith(status: status);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event $status')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_event == null) {
      return const Scaffold(body: Center(child: Text('Event not found')));
    }

    final userRole = _currentUser?.role?.toLowerCase() ?? '';
    final isStudent = userRole == 'student';
    final isAdmin = userRole == 'admin' || userRole == 'superadmin';
    final isCreator = _currentUser?.uid == _event!.createdBy;
    final canManage = !isStudent && (isCreator || isAdmin);
    
    final status = _event!.status.toUpperCase();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Banner
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_event!.title, style: const TextStyle(fontSize: 16)),
              background: Container(
                color: _getCategoryColor(_event!.category).withOpacity(0.2),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(_event!.category),
                    size: 80,
                    color: _getCategoryColor(_event!.category),
                  ),
                ),
              ),
            ),
            actions: [
              if (canManage)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      context.push('/$_institutionId/events/${_event!.id}/edit', extra: _event);
                    } else if (value == 'participants') {
                      context.push('/$_institutionId/events/${_event!.id}/participants', extra: _event!.title);
                    } else if (value == 'delete') {
                      // Add delete logic here if needed
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit Details')),
                    const PopupMenuItem(value: 'participants', child: Text('View Participants')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete Event', style: TextStyle(color: Colors.red))),
                  ],
                ),
            ],
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    children: [
                      _buildChip(_event!.category.toUpperCase(), _getCategoryColor(_event!.category)),
                      const SizedBox(width: 8),
                      _buildChip(status, _getStatusColor(status)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Title and Organizer
                  Text(
                    _event!.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        radius: 20,
                        child: Text(
                          _event!.organizerName.isNotEmpty ? _event!.organizerName[0].toUpperCase() : 'O',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Organized by', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(_event!.organizerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  
                  const Divider(height: 40),
                  
                  // Key Details
                  _buildDetailRow(Icons.calendar_month, 'Date & Time', 
                    '${_event!.formattedDate} at ${_event!.formattedTime}'),
                  const SizedBox(height: 20),
                  _buildDetailRow(Icons.location_on, 'Venue', _event!.venue),
                  const SizedBox(height: 20),
                  _buildDetailRow(Icons.group, 'Capacity', 
                    '${_event!.currentParticipants} / ${_event!.capacityLimit == 0 ? "Unlimited" : _event!.capacityLimit} registered'),
                  const SizedBox(height: 20),
                  _buildDetailRow(Icons.timer, 'Deadline', 
                    'Register before ${DateFormat('dd MMM, hh:mm a').format(_event!.registrationDeadline)}'),
                  
                  const Divider(height: 40),
                  
                  // Description
                  const Text('About this event', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    _event!.description,
                    style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                  ),
                  
                  const SizedBox(height: 100), // Padding for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomPanel(),
    );
  }

  Widget _buildBottomPanel() {
    final userRole = _currentUser?.role?.toLowerCase() ?? '';
    final isAdmin = userRole == 'admin' || userRole == 'superadmin';
    final status = _event!.status.toUpperCase();
    
    // If Admin and needs approval, show Approve/Reject buttons
    if (isAdmin && status == 'PENDING_APPROVAL') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateStatus('REJECTED'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('REJECT'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateStatus('APPROVED'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('APPROVE'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If Admin/Creator and approved, show Publish button
    if ((isAdmin || _currentUser?.uid == _event!.createdBy) && status == 'APPROVED') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _updateStatus('PUBLISHED'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('PUBLISH TO STUDENTS'),
            ),
          ),
        ),
      );
    }

    // Default registration panel for students/users
    bool canRegister = status == 'PUBLISHED' && !_event!.isFull && !_event!.isRegistrationClosed;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_event!.capacityLimit > 0)
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('REMAINING', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text(
                      '${_event!.capacityLimit - _event!.currentParticipants} Slots',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (canRegister && !_isRegistering) ? _handleRegistration : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isRegistering 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(canRegister ? 'REGISTER NOW' : (status != 'PUBLISHED' ? 'UNAVAILABLE' : (_event!.isFull ? 'EVENT FULL' : 'REGISTRATION CLOSED'))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PUBLISHED': return Colors.green;
      case 'PENDING_APPROVAL': return Colors.orange;
      case 'APPROVED': return Colors.blue;
      case 'REJECTED': return Colors.red;
      case 'CANCELLED': return Colors.grey;
      case 'COMPLETED': return Colors.indigo;
      default: return Colors.blueGrey;
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'academic': return Colors.blue;
      case 'placement': return Colors.indigo;
      case 'cultural': return Colors.purple;
      case 'administrative': return Colors.teal;
      case 'workshop': return Colors.orange;
      case 'sports': return Colors.red;
      default: return Colors.blueGrey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'academic': return Icons.school;
      case 'placement': return Icons.work;
      case 'cultural': return Icons.music_note;
      case 'workshop': return Icons.handyman;
      case 'sports': return Icons.sports_basketball;
      default: return Icons.event;
    }
  }
}
