import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/faculty_layout.dart';
import '../widgets/admin_layout.dart';
import '../widgets/student_layout.dart';

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
  bool _isDarkMode = false;

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
    if (mounted) {
      setState(() {
        _institutionId = institutionId;
      });
    }

    if (_institutionId != null) {
      await _fetchCurrentUser();
      if (_event == null) {
        await _fetchEvent();
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _fetchEvent() async {
    try {
      final event = await _eventService.getEventById(_institutionId!, widget.eventId);
      if (mounted) {
        setState(() {
          _event = event;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Error fetching event: $e');
      }
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final user = await _apiService.getMe(_institutionId!);
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
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
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchEvent();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegistering = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event status updated to $status'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final Color textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    
    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_event == null) {
      content = const Center(child: Text('Event not found'));
    } else {
      content = SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(textPrimary, textSecondary),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildMainContent(textPrimary, textSecondary)),
                      const SizedBox(width: 32),
                      Expanded(flex: 1, child: _buildSidePanel(textPrimary, textSecondary)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildMainContent(textPrimary, textSecondary),
                      const SizedBox(height: 32),
                      _buildSidePanel(textPrimary, textSecondary),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      );
    }

    final role = _currentUser?.role?.toLowerCase();
    if (role == 'admin') {
      return AdminLayout(title: 'Event Details', child: content);
    } else if (role == 'faculty') {
      return FacultyLayout(title: 'Event Details', child: content);
    } else {
      return StudentLayout(title: 'Event Details', child: content);
    }
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    final userRole = _currentUser?.role?.toLowerCase() ?? '';
    final isStudent = userRole == 'student';
    final isAdmin = userRole == 'admin' || userRole == 'superadmin';
    final isCreator = _currentUser?.uid == _event!.createdBy;
    final canManage = !isStudent && (isCreator || isAdmin);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildCategoryChip(_event!.category),
                  const SizedBox(width: 12),
                  _buildStatusChip(_event!.status),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _event!.title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
        if (canManage)
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push('/$_institutionId/events/${_event!.id}/participants', extra: _event!.title),
                icon: const Icon(Icons.people_rounded, size: 18),
                label: const Text('Participants'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => context.push('/$_institutionId/events/${_event!.id}/edit', extra: _event),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMainContent(Color textPrimary, Color textSecondary) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Area
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_getCategoryColor(_event!.category).withOpacity(0.8), _getCategoryColor(_event!.category).withOpacity(0.4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Center(
              child: Icon(
                _getCategoryIcon(_event!.category),
                size: 80,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About this Event',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 16),
                Text(
                  _event!.description,
                  style: TextStyle(fontSize: 16, color: textSecondary, height: 1.6),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),
                Text(
                  'Organized by',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                      child: Text(
                        _event!.organizerName.isNotEmpty ? _event!.organizerName[0].toUpperCase() : 'O',
                        style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _event!.organizerName,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        Text(
                          'Institutional Organizer',
                          style: TextStyle(fontSize: 13, color: textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel(Color textPrimary, Color textSecondary) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoItem(Icons.calendar_today_rounded, 'Date', _event!.formattedDate, textPrimary, textSecondary),
              const SizedBox(height: 24),
              _buildInfoItem(Icons.access_time_rounded, 'Time', _event!.formattedTime, textPrimary, textSecondary),
              const SizedBox(height: 24),
              _buildInfoItem(Icons.location_on_rounded, 'Venue', _event!.venue, textPrimary, textSecondary),
              const SizedBox(height: 24),
              _buildInfoItem(Icons.group_rounded, 'Capacity', '${_event!.currentParticipants} / ${_event!.capacityLimit == 0 ? "Unlimited" : _event!.capacityLimit}', textPrimary, textSecondary),
              const SizedBox(height: 32),
              _buildRegistrationPanel(),
            ],
          ),
        ),
        if (_currentUser?.role != 'student') ...[
          const SizedBox(height: 24),
          _buildManagementPanel(cardColor, borderColor, textPrimary, textSecondary),
        ],
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildRegistrationPanel() {
    final status = _event!.status.toUpperCase();
    bool canRegister = status == 'PUBLISHED' && !_event!.isFull && !_event!.isRegistrationClosed;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: (canRegister && !_isRegistering) ? _handleRegistration : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            disabledBackgroundColor: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
          child: _isRegistering 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                canRegister ? 'REGISTER FOR EVENT' : (status != 'PUBLISHED' ? 'NOT AVAILABLE' : (_event!.isFull ? 'EVENT FULL' : 'REGISTRATION CLOSED')),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
        ),
        if (canRegister)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Deadline: ${DateFormat('dd MMM, hh:mm a').format(_event!.registrationDeadline)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildManagementPanel(Color cardColor, Color borderColor, Color textPrimary, Color textSecondary) {
    final userRole = _currentUser?.role?.toLowerCase() ?? '';
    final isAdmin = userRole == 'admin' || userRole == 'superadmin';
    final status = _event!.status.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary)),
          const SizedBox(height: 16),
          if (isAdmin && status == 'PENDING_APPROVAL') ...[
            _actionButton('Approve Event', const Color(0xFF10B981), () => _updateStatus('APPROVED')),
            const SizedBox(height: 12),
            _actionButton('Reject Event', Colors.redAccent, () => _updateStatus('REJECTED'), isOutline: true),
          ] else if (status == 'APPROVED') ...[
            _actionButton('Publish to Students', const Color(0xFF4F46E5), () => _updateStatus('PUBLISHED')),
          ] else ...[
             Text('No management actions available for current status ($status).', style: TextStyle(fontSize: 13, color: textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onPressed, {bool isOutline = false}) {
    if (isOutline) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final color = _getCategoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PUBLISHED': return const Color(0xFF10B981);
      case 'PENDING_APPROVAL': return const Color(0xFFF59E0B);
      case 'APPROVED': return const Color(0xFF3B82F6);
      case 'REJECTED': return const Color(0xFFEF4444);
      case 'CANCELLED': return const Color(0xFF64748B);
      case 'COMPLETED': return const Color(0xFF6366F1);
      default: return const Color(0xFF64748B);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'academic': return const Color(0xFF3B82F6);
      case 'placement': return const Color(0xFF6366F1);
      case 'cultural': return const Color(0xFFA855F7);
      case 'administrative': return const Color(0xFF14B8A6);
      case 'workshop': return const Color(0xFFF59E0B);
      case 'sports': return const Color(0xFFEF4444);
      default: return const Color(0xFF64748B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'academic': return Icons.school_rounded;
      case 'placement': return Icons.work_rounded;
      case 'cultural': return Icons.music_note_rounded;
      case 'workshop': return Icons.handyman_rounded;
      case 'sports': return Icons.sports_basketball_rounded;
      default: return Icons.event_rounded;
    }
  }
}
