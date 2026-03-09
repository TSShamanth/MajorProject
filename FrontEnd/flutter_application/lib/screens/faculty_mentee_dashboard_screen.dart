import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../models/mentor_meeting_model.dart';
import '../models/mentee_concern_model.dart';
import '../services/mentorship_service.dart';
import '../services/session_manager.dart';
import '../widgets/faculty_layout.dart';

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
  bool _isDarkMode = false;

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

  void _showRespondToConcernDialog(MenteeConcern concern) {
    final remarksController = TextEditingController();
    String selectedStatus = 'Resolved';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          title: Text('Respond to: ${concern.concernType}', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                items: ['In-Progress', 'Resolved'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setDialogState(() => selectedStatus = val!),
                decoration: InputDecoration(
                  labelText: 'Status',
                  labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarksController,
                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Mentor Remarks',
                  labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  border: const OutlineInputBorder(),
                ),
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
                  if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
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
          backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          title: Text('Schedule Future Meeting', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<UserModel>(
                  dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                  style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Select Mentee',
                    labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  value: selectedMentee,
                  items: _mentees.map((m) => DropdownMenuItem(value: m, child: Text(m.displayName))).toList(),
                  onChanged: (val) => setDialogState(() => selectedMentee = val),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: topicController,
                  style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Meeting Topic',
                    labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMode,
                  dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                  style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Meeting Mode',
                    labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  items: ['Offline', 'Online'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) => setDialogState(() => selectedMode = val!),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text('Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
                  trailing: Icon(Icons.calendar_today, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
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
                  notes: topicController.text,
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
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
          backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          title: Text('Complete Meeting with ${meeting.studentName}', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: notesController,
                  style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Discussion Notes',
                    labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: followUpController,
                  style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Next Steps / Follow-up',
                    labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Attachments (Links)', style: TextStyle(fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black)),
                ...links.map((l) => ListTile(
                  title: Text(l, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.grey[300] : Colors.black)), 
                  dense: true, 
                  trailing: IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 18), onPressed: () => setDialogState(() => links.remove(l)))
                )),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: linkController,
                        style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Add resource URL...',
                          hintStyle: TextStyle(color: _isDarkMode ? Colors.grey[500] : Colors.grey[400]),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(icon: Icon(Icons.add_link, color: _isDarkMode ? Colors.blue[400] : Colors.blue), onPressed: () {
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              child: const Text('Mark Completed'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FacultyLayout(
      title: 'Mentee Management',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Mentees', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
      ],
      child: Column(
        children: [
          Container(
            color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF4F46E5),
              unselectedLabelColor: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
              indicatorColor: const Color(0xFF4F46E5),
              tabs: const [
                Tab(text: 'Mentees'),
                Tab(text: 'Concerns'),
                Tab(text: 'Meetings'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMenteeListTab(),
                      _buildConcernList(),
                      _buildMeetingListTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenteeListTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(Icons.search_rounded, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Search by name or USN...',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              FilterChip(
                label: const Text('At Risk'),
                selected: _showAtRiskOnly,
                selectedColor: Colors.red.withOpacity(0.2),
                labelStyle: TextStyle(color: _showAtRiskOnly ? Colors.red : (_isDarkMode ? Colors.grey[400] : Colors.grey[600])),
                onSelected: (val) => setState(() => _showAtRiskOnly = val),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _showScheduleMeetingDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Meeting'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: _filteredMentees.isEmpty
                ? Center(child: Text('No mentees found', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600])))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/$_institutionId/faculty/mentees/${mentee.uid}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                  shape: BoxShape.circle,
                ),
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'USN: ${mentee.usn ?? "N/A"} • Sem ${mentee.sem ?? "N/A"}',
                      style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: attColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: attColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${att.toStringAsFixed(1)}%',
                      style: TextStyle(color: attColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text('Attendance', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right_rounded, color: _isDarkMode ? Colors.grey[600] : Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConcernList() {
    final pending = _concerns.where((c) => c.status != 'Resolved').toList();
    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No pending concerns. Good job!', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final c = pending[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Text(c.concernType, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () => _showRespondToConcernDialog(c),
                    icon: const Icon(Icons.reply_rounded, size: 18),
                    label: const Text('Respond'),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF4F46E5)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(c.description, style: TextStyle(fontSize: 14, color: _isDarkMode ? Colors.grey[300] : Colors.black87)),
              const SizedBox(height: 8),
              Text('Date: ${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}', style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.grey[500] : Colors.grey[600])),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeetingListTab() {
    final requests = _meetings.where((m) => m.status == 'Requested').toList();
    final history = _meetings.where((m) => m.status != 'Requested').toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (requests.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.notification_important_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text('Meeting Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 12),
          ...requests.map((m) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('Proposed: ${m.date.day}/${m.date.month} • ${m.notes}', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.check_circle_rounded, color: Colors.green), onPressed: () => _handleMeetingAction(m.id!, 'Scheduled')),
                IconButton(icon: const Icon(Icons.cancel_rounded, color: Colors.red), onPressed: () => _handleMeetingAction(m.id!, 'Cancelled')),
              ],
            ),
          )),
          const SizedBox(height: 24),
        ],
        Row(
          children: [
            const Icon(Icons.history_rounded, color: Color(0xFF4F46E5), size: 20),
            const SizedBox(width: 8),
            Text('Meeting History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937))),
          ],
        ),
        const SizedBox(height: 12),
        ...history.map((m) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            title: Text(m.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text('${m.date.day}/${m.date.month} • ${m.status}', style: TextStyle(color: m.status == 'Scheduled' ? Colors.blue : Colors.grey, fontSize: 13)),
            trailing: m.status == 'Scheduled' 
              ? ElevatedButton(
                  onPressed: () => _showCompleteMeetingDialog(m),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    elevation: 0,
                  ),
                  child: const Text('Complete', style: TextStyle(fontSize: 12)),
                )
              : Icon(Icons.chevron_right_rounded, color: _isDarkMode ? Colors.grey[600] : Colors.grey[400]),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('Notes: ${m.notes}', style: TextStyle(color: _isDarkMode ? Colors.grey[300] : Colors.black87)),
                    if (m.followUpAction.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Follow-up: ${m.followUpAction}', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w500)),
                    ],
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
