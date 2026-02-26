import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/placement_drive_model.dart';
import '../models/placement_application_model.dart';
import '../services/placement_service.dart';

class DriveDetailsScreen extends StatefulWidget {
  final String driveId;
  const DriveDetailsScreen({super.key, required this.driveId});

  @override
  State<DriveDetailsScreen> createState() => _DriveDetailsScreenState();
}

class _DriveDetailsScreenState extends State<DriveDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PlacementDriveModel? _drive;
  List<PlacementApplicationModel> _allApplications = [];
  List<PlacementApplicationModel> _filteredApplications = [];
  bool _isLoading = true;
  PlacementService? _service;
  
  final Set<String> _selectedStudentIds = {};
  String _currentStage = 'Applied';

  final List<String> _stages = ['Applied', 'Shortlisted', 'OA', 'Technical', 'HR', 'Offered'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _stages.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _initializeData();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _currentStage = _stages[_tabController.index];
      _selectedStudentIds.clear();
      _filterByStage();
    });
  }

  Future<void> _initializeData() async {
    final institutionId = GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'];
    if (institutionId == null) return;

    _service = PlacementService(institutionId: institutionId);
    try {
      final drives = await _service!.getPlacementDrives();
      final applications = await _service!.getApplications(driveId: widget.driveId);
      
      setState(() {
        _drive = drives.firstWhere((d) => d.id == widget.driveId);
        _allApplications = applications;
        _isLoading = false;
        _filterByStage();
      });
    } catch (e) {
      debugPrint('Error loading drive details: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterByStage() {
    setState(() {
      _filteredApplications = _allApplications.where((app) {
        if (_currentStage == 'Applied') return true;
        return app.status == _currentStage || app.currentRound == _currentStage;
      }).toList();
    });
  }

  Future<void> _moveSelectedToStage(String targetStage) async {
    if (_service == null || _selectedStudentIds.isEmpty) return;
    
    final messenger = ScaffoldMessenger.of(context);
    try {
      for (var id in _selectedStudentIds) {
        await _service!.updateApplicationStatus(id, targetStage, targetStage);
      }
      messenger.showSnackBar(SnackBar(content: Text('Moved ${_selectedStudentIds.length} students to $targetStage')));
      _initializeData(); // Refresh
    } catch (e) {
      debugPrint('Error moving students: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_drive == null) return const Scaffold(body: Center(child: Text('Drive not found')));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_drive!.companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(_drive!.jobRole, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: () {}, tooltip: 'Download All Resumes'),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Left Side: Pipeline List
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildPipelineHeader(),
                if (_selectedStudentIds.isNotEmpty) _buildBulkActionBar(),
                Expanded(child: _buildStudentList()),
              ],
            ),
          ),
          
          // Right Side: JAF & Quick Stats
          Container(
            width: 350,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: _buildJAFPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineHeader() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF4F46E5),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF4F46E5),
        tabs: _stages.map((s) {
          int count = _allApplications.where((app) => s == 'Applied' ? true : (app.status == s || app.currentRound == s)).length;
          return Tab(
            child: Row(
              children: [
                Text(s),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                  child: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBulkActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: const Color(0xFFEEF2FF),
      child: Row(
        children: [
          Text('${_selectedStudentIds.length} students selected', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showBroadcastDialog(),
            icon: const Icon(Icons.campaign_outlined, size: 18),
            label: const Text('Broadcast'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _moveSelectedToStage('Rejected'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
            child: const Text('Reject All'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _showMoveStageDialog(),
            child: const Text('Move to Next Stage'),
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Broadcast to ${_selectedStudentIds.length} Students'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: messageController, maxLines: 4, decoration: const InputDecoration(labelText: 'Message Body', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast sent successfully!')));
            },
            child: const Text('Send Emails & Notifications'),
          ),
        ],
      ),
    );
  }

  void _showMoveStageDialog() {
    String selectedStage = _stages.last;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Move Selected Students'),
          content: DropdownButtonFormField<String>(
            value: selectedStage,
            decoration: const InputDecoration(labelText: 'Target Stage'),
            items: _stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) => setState(() => selectedStage = val!),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _moveSelectedToStage(selectedStage);
              },
              child: const Text('Confirm Move'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    if (_filteredApplications.isEmpty) {
      return Center(child: Text('No students in this stage', style: TextStyle(color: Colors.grey[400])));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredApplications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final app = _filteredApplications[index];
        final isSelected = _selectedStudentIds.contains(app.id);
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (val) {
                setState(() {
                  if (val!) {
                    _selectedStudentIds.add(app.id);
                  } else {
                    _selectedStudentIds.remove(app.id);
                  }
                });
              },
            ),
            title: Text(app.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Round: ${app.currentRound} • Applied on ${app.appliedDate}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(onPressed: () => _showStudentProfile(app), child: const Text('View Profile')),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStudentProfile(PlacementApplicationModel app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person, color: Color(0xFF4F46E5)),
            const SizedBox(width: 8),
            Text(app.studentName),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Academic Details', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('CGPA: 8.5 • Branch: CSE • Batch: 2026\n10th: 92% • 12th: 89% • Backlogs: 0'),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Application Status', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Round: ${app.currentRound}\nStatus: ${app.status}\nApplied On: ${app.appliedDate}'),
              ),
              const Divider(),
              const Text('Resume / CV', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${app.studentName.replaceAll(" ", "_")}_Resume.pdf')),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Download'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _selectedStudentIds.clear();
              _selectedStudentIds.add(app.id);
              _showMoveStageDialog();
            },
            child: const Text('Move Stage'),
          ),
        ],
      ),
    );
  }

  Widget _buildJAFPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Job Announcement Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildJAFRow('Hiring Type', 'Full Time Employment'),
          _buildJAFRow('CTC Package', '${_drive!.salaryPackage} LPA'),
          _buildJAFRow('Fixed Base', '12.5 LPA'),
          _buildJAFRow('Bond', 'No Bond'),
          const Divider(height: 32),
          const Text('Eligibility Criteria', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildCriteriaChip('CGPA: ${_drive!.minCgpa}+'),
          _buildCriteriaChip('Backlogs: Max ${_drive!.maxBacklogs}'),
          _buildCriteriaChip('Dept: ${_drive!.allowedDepartments.join(", ")}'),
          const Divider(height: 32),
          const Text('About the Role', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_drive!.eligibilityCriteria, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.5)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auto-fetching eligible students based on JAF criteria...')),
                );
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Fetch Eligible Students'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJAFRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildCriteriaChip(String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
