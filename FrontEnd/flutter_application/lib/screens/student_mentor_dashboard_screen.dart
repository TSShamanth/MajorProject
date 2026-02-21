import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../models/mentor_meeting_model.dart';
import '../models/mentee_concern_model.dart';
import '../services/mentorship_service.dart';
import '../services/session_manager.dart';

class StudentMentorDashboardScreen extends StatefulWidget {
  const StudentMentorDashboardScreen({super.key});

  @override
  State<StudentMentorDashboardScreen> createState() => _StudentMentorDashboardScreenState();
}

class _StudentMentorDashboardScreenState extends State<StudentMentorDashboardScreen> {
  final MentorshipService _mentorshipService = MentorshipService();
  String? _institutionId;
  UserModel? _mentor;
  List<MentorMeeting> _meetings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      _institutionId = await SessionManager.getInstitutionId();
      if (_institutionId != null) {
        final mentor = await _mentorshipService.getMentor(_institutionId!);
        final meetings = await _mentorshipService.getMeetings(_institutionId!);
        if (mounted) {
          setState(() {
            _mentor = mentor;
            _meetings = meetings;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading mentor data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  void _showRequestMeetingDialog() {
    final topicController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedMode = 'Offline';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Request Meeting'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: topicController, decoration: const InputDecoration(labelText: 'Meeting Topic')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMode,
                decoration: const InputDecoration(labelText: 'Preferred Mode'),
                items: ['Offline', 'Online'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setDialogState(() => selectedMode = val!),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Date: ${selectedDate.day}/${selectedDate.month}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);
                
                final meeting = MentorMeeting(
                  mentorId: _mentor!.uid,
                  studentId: '', // Backend sets it
                  studentName: '', // Backend sets it
                  date: selectedDate,
                  notes: topicController.text,
                  followUpAction: '',
                  status: 'Requested',
                  mode: selectedMode,
                );
                try {
                  await _mentorshipService.createMeeting(_institutionId!, meeting);
                  if (mounted) {
                    navigator.pop();
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRaiseConcernDialog() {
    final descriptionController = TextEditingController();
    String selectedType = 'Academic';
    String selectedPriority = 'Medium';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Raise Concern to Mentor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Academic', 'Personal', 'Placement', 'Attendance']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedType = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['Low', 'Medium', 'High']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedPriority = val!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Describe your concern',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (descriptionController.text.isEmpty) return;
                
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);

                final concern = MenteeConcern(
                  studentId: '', // Set by backend
                  mentorId: _mentor?.uid ?? '',
                  concernType: selectedType,
                  description: descriptionController.text,
                  createdAt: DateTime.now(),
                  priority: selectedPriority,
                );
                try {
                  await _mentorshipService.raiseConcern(_institutionId!, concern);
                  if (mounted) {
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Concern raised successfully'), backgroundColor: Colors.green),
                    );
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('My Mentor'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: _mentor == null 
        ? const Center(child: Text('No mentor assigned yet.'))
        : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMentorProfile(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  _buildConcernsHistory(),
                  const SizedBox(height: 24),
                  _buildMeetingHistory(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildMentorProfile() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2), width: 2),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFFEEF2FF),
              backgroundImage: _mentor?.photoUrl != null ? NetworkImage(_mentor!.photoUrl!) : null,
              child: _mentor?.photoUrl == null ? const Icon(Icons.person, size: 48, color: Color(0xFF4F46E5)) : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(_mentor?.displayName ?? 'N/A', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          Text(_mentor?.programme ?? 'Faculty', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.email_outlined, 'Email', _mentor?.email ?? 'N/A'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.phone_outlined, 'Phone', _mentor?.phone ?? 'N/A'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.business_outlined, 'School', _mentor?.school ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF4F46E5)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1F2937))),
          ],
        ),
      ],
    );
  }

  Widget _buildConcernsHistory() {
    return FutureBuilder<List<MenteeConcern>>(
      future: _mentorshipService.getConcerns(_institutionId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Concerns', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...snapshot.data!.map((c) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(c.concernType, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(c.mentorRemarks ?? 'Awaiting mentor response...'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.status == 'Resolved' ? Colors.green.shade50 : Colors.blue.shade50, 
                    borderRadius: BorderRadius.circular(6)
                  ),
                  child: Text(c.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c.status == 'Resolved' ? Colors.green : Colors.blue)),
                ),
              ),
            )),
          ],
        );
      }
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(Icons.calendar_month, 'Request Meeting', const Color(0xFF4F46E5), _showRequestMeetingDialog),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(Icons.report_problem_outlined, 'Raise Concern', Colors.redAccent, _showRaiseConcernDialog),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingHistory() {
    final upcoming = _meetings.where((m) => m.status == 'Requested' || m.status == 'Scheduled').toList();
    final past = _meetings.where((m) => m.status == 'Completed' || m.status == 'Cancelled').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (upcoming.isNotEmpty) ...[
          const Text('Upcoming Meetings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
          const SizedBox(height: 12),
          ...upcoming.map((m) => _buildMeetingCard(m)),
          const SizedBox(height: 24),
        ],
        const Text('Meeting History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        past.isEmpty 
          ? const Text('No past meetings recorded.')
          : Column(children: past.map((m) => _buildMeetingCard(m)).toList()),
      ],
    );
  }

  Widget _buildMeetingCard(MentorMeeting meeting) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;

    if (meeting.status == 'Requested') {
      statusColor = Colors.orange;
      statusIcon = Icons.pending_outlined;
    } else if (meeting.status == 'Scheduled') {
      statusColor = Colors.blue;
      statusIcon = Icons.calendar_today;
    } else if (meeting.status == 'Completed') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (meeting.status == 'Cancelled') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Text(meeting.notes.isEmpty ? 'Meeting' : meeting.notes, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${meeting.date.day}/${meeting.date.month}/${meeting.date.year} - ${meeting.status}', 
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
            Text('Mode: ${meeting.mode}', style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meeting.status == 'Completed') ...[
                  const Text('Mentor Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(meeting.notes.isEmpty ? 'No notes provided.' : meeting.notes, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
                  if (meeting.followUpAction.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Follow-up:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(meeting.followUpAction, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
                  ],
                  if (meeting.attachments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Attachments:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: meeting.attachments.map((link) => ActionChip(
                        label: const Text('View Resource', style: TextStyle(fontSize: 11)),
                        backgroundColor: const Color(0xFFEEF2FF),
                        side: const BorderSide(color: Color(0xFF4F46E5), width: 0.5),
                        avatar: const Icon(Icons.link, size: 14, color: Color(0xFF4F46E5)),
                        onPressed: () => _launchURL(link),
                      )).toList(),
                    ),
                  ],
                ] else
                  Text(
                    meeting.status == 'Requested' ? 'Waiting for mentor to approve this request.' : 'Meeting scheduled. Discussion notes will appear here after the meeting.',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
