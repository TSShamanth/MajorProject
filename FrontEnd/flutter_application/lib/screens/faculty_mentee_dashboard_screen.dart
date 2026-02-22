import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../models/mentor_meeting_model.dart';
import '../models/mentee_concern_model.dart';
import '../services/mentorship_service.dart';
import '../services/session_manager.dart';

class FacultyMenteeDashboardScreen extends StatefulWidget {
  const FacultyMenteeDashboardScreen({super.key});

  @override
  State<FacultyMenteeDashboardScreen> createState() => _FacultyMenteeDashboardScreenState();
}

class _FacultyMenteeDashboardScreenState extends State<FacultyMenteeDashboardScreen> with SingleTickerProviderStateMixin {
  final MentorshipService _mentorshipService = MentorshipService();
  String? _institutionId;
  List<UserModel> _mentees = [];
  List<MentorMeeting> _meetings = [];
  List<MenteeConcern> _concerns = [];
  bool _isLoading = true;
  late TabController _tabController;

  // Search and Filter state
  final TextEditingController _searchController = TextEditingController();
  bool _showAtRiskOnly = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> get _filteredMentees {
    return _mentees.where((m) {
      final matchesSearch = m.displayName.toLowerCase().contains(_searchQuery) || 
                           (m.usn?.toLowerCase().contains(_searchQuery) ?? false);
      final isAtRisk = (m.attendancePercentage ?? 100.0) < 75.0;
      if (_showAtRiskOnly) return matchesSearch && isAtRisk;
      return matchesSearch;
    }).toList();
  }

  Future<void> _handleMeetingAction(String meetingId, String newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _mentorshipService.updateMeetingStatus(_institutionId!, meetingId, newStatus);
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Meeting $newStatus'), backgroundColor: Colors.green));
        _loadData();
      }
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      _institutionId = await SessionManager.getInstitutionId();
      if (_institutionId != null) {
        final mentees = await _mentorshipService.getMentees(_institutionId!);
        final meetings = await _mentorshipService.getMeetings(_institutionId!);
        final concerns = await _mentorshipService.getConcerns(_institutionId!);
        if (mounted) {
          setState(() {
            _mentees = mentees;
            _meetings = meetings;
            _concerns = concerns;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRespondToConcernDialog(MenteeConcern concern) {
    final remarksController = TextEditingController();
    String selectedStatus = 'Resolved';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Respond to: ${concern.concernType}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                items: ['In-Progress', 'Resolved'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setDialogState(() => selectedStatus = val!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(labelText: 'Mentor Remarks', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);
                try {
                  await _mentorshipService.updateConcernStatus(_institutionId!, concern.id!, selectedStatus, remarks: remarksController.text);
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
              child: const Text('Send Response'),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleMeetingDialog() {
    UserModel? selectedMentee;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final topicController = TextEditingController();
    String selectedMode = 'Offline';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Schedule Future Meeting'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<UserModel>(
                decoration: const InputDecoration(labelText: 'Select Mentee'),
                value: selectedMentee,
                items: _mentees.map((m) => DropdownMenuItem(value: m, child: Text(m.displayName))).toList(),
                onChanged: (val) => setDialogState(() => selectedMentee = val),
              ),
              const SizedBox(height: 16),
              TextField(controller: topicController, decoration: const InputDecoration(labelText: 'Meeting Topic')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMode,
                decoration: const InputDecoration(labelText: 'Meeting Mode'),
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
                    lastDate: DateTime.now().add(const Duration(days: 90)),
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
                if (selectedMentee == null) return;
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);
                final meeting = MentorMeeting(
                  mentorId: '',
                  studentId: selectedMentee!.uid,
                  studentName: selectedMentee!.displayName,
                  date: selectedDate,
                  notes: topicController.text, // Used as topic for scheduled
                  followUpAction: '',
                  status: 'Scheduled',
                  mode: selectedMode,
                  actionItems: [],
                );
                try {
                  await _mentorshipService.createMeeting(_institutionId!, meeting);
                  if (mounted) {
                    navigator.pop();
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompleteMeetingDialog(MentorMeeting meeting) {
    final notesController = TextEditingController();
    final followUpController = TextEditingController();
    final linkController = TextEditingController();
    List<String> links = [];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Complete Meeting with ${meeting.studentName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Discussion Notes', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: followUpController,
                  decoration: const InputDecoration(labelText: 'Next Steps / Follow-up', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const Text('Attachments (Links)', style: TextStyle(fontWeight: FontWeight.bold)),
                ...links.map((l) => ListTile(
                  title: Text(l, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)), 
                  dense: true, 
                  trailing: IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 18), onPressed: () => setDialogState(() => links.remove(l)))
                )),
                Row(
                  children: [
                    Expanded(child: TextField(controller: linkController, decoration: const InputDecoration(hintText: 'Add resource URL...', isDense: true))),
                    IconButton(icon: const Icon(Icons.add_link), onPressed: () {
                      if (linkController.text.isNotEmpty) {
                        setDialogState(() => links.add(linkController.text));
                        linkController.clear();
                      }
                    }),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);
                try {
                  final data = {
                    'notes': notesController.text,
                    'followUpAction': followUpController.text,
                    'attachments': links,
                  };

                  await _mentorshipService.completeMeeting(_institutionId!, meeting.id!, data);
                  
                  if (mounted) {
                    navigator.pop();
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Mark Completed'),
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Mentorship Dashboard'),
        backgroundColor: const Color(0xFF312E81),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Mentees'),
            Tab(text: 'Concerns'),
            Tab(text: 'Meetings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMenteeListTab(),
          _buildConcernList(),
          _buildMeetingListTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScheduleMeetingDialog,
        label: const Text('Schedule Meeting'),
        icon: const Icon(Icons.calendar_today),
        backgroundColor: const Color(0xFF4F46E5),
      ),
    );
  }

  Widget _buildMenteeListTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or USN...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('At Risk'),
                selected: _showAtRiskOnly,
                selectedColor: Colors.red.shade100,
                onSelected: (val) => setState(() => _showAtRiskOnly = val),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredMentees.length,
              itemBuilder: (context, index) => _buildMenteeCard(_filteredMentees[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenteeCard(UserModel mentee) {
    final att = mentee.attendancePercentage ?? 0.0;
    final attColor = att < 75 ? Colors.red : Colors.green;

    return InkWell(
      onTap: () => context.push('/$_institutionId/faculty/mentees/${mentee.uid}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle),
              child: Center(
                child: Text(
                  mentee.displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mentee.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'USN: ${mentee.usn ?? "N/A"} • Sem ${mentee.sem ?? "N/A"}',
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: attColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '${att.toStringAsFixed(1)}%',
                    style: TextStyle(color: attColor, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Text('Attendance', style: TextStyle(color: Color(0xFF6B7280), fontSize: 9)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }

  Widget _buildConcernList() {
    final pending = _concerns.where((c) => c.status != 'Resolved').toList();
    if (pending.isEmpty) return const Center(child: Text('No pending concerns. Good job!'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final c = pending[index];
        return Card(
          child: ListTile(
            title: Text(c.concernType, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(c.description),
            trailing: ElevatedButton(onPressed: () => _showRespondToConcernDialog(c), child: const Text('Respond')),
          ),
        );
      },
    );
  }

  Widget _buildMeetingListTab() {
    final requests = _meetings.where((m) => m.status == 'Requested').toList();
    final upcoming = _meetings.where((m) => m.status != 'Requested').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (requests.isNotEmpty) ...[
          const Text('Meeting Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 8),
          ...requests.map((m) => Card(
            color: Colors.orange.shade50,
            child: ListTile(
              title: Text(m.studentName),
              subtitle: Text('Proposed: ${m.date.day}/${m.date.month} - Topic: ${m.notes}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _handleMeetingAction(m.id!, 'Scheduled')),
                  IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _handleMeetingAction(m.id!, 'Cancelled')),
                ],
              ),
            ),
          )),
          const Divider(height: 32),
        ],
        const Text('Meeting History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...upcoming.map((m) => Card(
          child: ExpansionTile(
            title: Text('${m.studentName} - ${m.date.day}/${m.date.month}'),
            subtitle: Text(m.status, style: TextStyle(color: m.status == 'Scheduled' ? Colors.blue : Colors.grey)),
            trailing: m.status == 'Scheduled' 
              ? ElevatedButton(
                  onPressed: () => _showCompleteMeetingDialog(m),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0)),
                  child: const Text('Complete', style: TextStyle(fontSize: 12)),
                )
              : null,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notes: ${m.notes}'),
                  ],
                ),
              )
            ],
          ),
        )),
      ],
    );
  }
}
