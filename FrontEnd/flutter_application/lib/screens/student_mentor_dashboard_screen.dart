import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../models/mentor_meeting_model.dart';
import '../models/mentee_concern_model.dart';
import '../services/mentorship_service.dart';
import '../services/session_manager.dart';
import '../widgets/student_layout.dart';

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Request Meeting', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: topicController, 
                decoration: InputDecoration(
                  labelText: 'Meeting Topic',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.topic_rounded),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMode,
                decoration: InputDecoration(
                  labelText: 'Preferred Mode',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.videocam_rounded),
                ),
                items: ['Offline', 'Online'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setDialogState(() => selectedMode = val!),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 12),
                      Text('Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', 
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Raise Concern to Mentor', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['Academic', 'Personal', 'Placement', 'Attendance']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedType = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['Low', 'Medium', 'High']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedPriority = val!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Describe your concern',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: 'Mentorship Dashboard',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('My Mentor', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _mentor == null 
          ? _buildNoMentorState()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF4F46E5),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMentorProfileHeader(),
                    const SizedBox(height: 32),
                    const Text('Quick Actions', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5)),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 32),
                    _buildConcernsHistory(),
                    const SizedBox(height: 32),
                    _buildMeetingHistory(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNoMentorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_off_rounded, size: 64, color: Colors.orange),
          ),
          const SizedBox(height: 24),
          const Text('No Mentor Assigned', 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          const Text('Please contact your department head to assign a mentor.',
            style: TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildMentorProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2), width: 2),
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: const Color(0xFFEEF2FF),
              backgroundImage: _mentor?.photoUrl != null ? NetworkImage(_mentor!.photoUrl!) : null,
              child: _mentor?.photoUrl == null ? const Icon(Icons.person_rounded, size: 40, color: Color(0xFF4F46E5)) : null,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_mentor?.displayName ?? 'N/A', 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5)),
                Text(_mentor?.programme ?? 'Academic Mentor', 
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildHeaderInfoChip(Icons.email_outlined, _mentor?.email ?? 'N/A'),
                    _buildHeaderInfoChip(Icons.phone_outlined, _mentor?.phone ?? 'N/A'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4B5563)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildModernActionButton(
            Icons.calendar_today_rounded, 
            'Request Meeting', 
            const Color(0xFF4F46E5), 
            _showRequestMeetingDialog
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildModernActionButton(
            Icons.report_problem_rounded, 
            'Raise Concern', 
            const Color(0xFFEF4444), 
            _showRaiseConcernDialog
          ),
        ),
      ],
    );
  }

  Widget _buildModernActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
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
            const Text('Recent Concerns', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5)),
            const SizedBox(height: 16),
            ...snapshot.data!.map((c) => _buildConcernCard(c)),
          ],
        );
      }
    );
  }

  Widget _buildConcernCard(MenteeConcern concern) {
    final isResolved = concern.status == 'Resolved';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isResolved ? Colors.green : Colors.orange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isResolved ? Icons.check_circle_rounded : Icons.pending_rounded, 
              color: isResolved ? Colors.green : Colors.orange, 
              size: 20
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(concern.concernType, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1F2937))),
                const SizedBox(height: 2),
                Text(concern.mentorRemarks ?? 'Awaiting mentor response...', 
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isResolved ? Colors.green : Colors.orange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(concern.status.toUpperCase(), 
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isResolved ? Colors.green : Colors.orange)),
          ),
        ],
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
          const Text('Upcoming Meetings', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5), letterSpacing: -0.5)),
          const SizedBox(height: 16),
          ...upcoming.map((m) => _buildMeetingCard(m)),
          const SizedBox(height: 24),
        ],
        const Text('Meeting History', 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5)),
        const SizedBox(height: 16),
        past.isEmpty 
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Column(
                children: [
                  Icon(Icons.history_rounded, size: 40, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  const Text('No past meetings recorded.', style: TextStyle(color: Color(0xFF6B7280))),
                ],
              ),
            )
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          title: Text(meeting.notes.isEmpty ? 'Meeting' : meeting.notes, 
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1F2937))),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text('${meeting.date.day}/${meeting.date.month}/${meeting.date.year}', 
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Text('•', style: TextStyle(color: Colors.grey[400])),
                const SizedBox(width: 8),
                Text(meeting.mode, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(meeting.status.toUpperCase(), 
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor)),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  if (meeting.status == 'Completed') ...[
                    _buildExpandedDetail('Mentor Notes', meeting.notes.isEmpty ? 'No notes provided.' : meeting.notes),
                    if (meeting.followUpAction.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildExpandedDetail('Follow-up Action', meeting.followUpAction),
                    ],
                    if (meeting.attachments.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Resources & Attachments', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1F2937))),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: meeting.attachments.map((link) => ActionChip(
                          label: const Text('View Resource', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          backgroundColor: const Color(0xFFEEF2FF),
                          side: const BorderSide(color: Color(0xFF4F46E5), width: 0.5),
                          avatar: const Icon(Icons.link_rounded, size: 14, color: Color(0xFF4F46E5)),
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
      ),
    );
  }

  Widget _buildExpandedDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1F2937))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.5)),
      ],
    );
  }
}
