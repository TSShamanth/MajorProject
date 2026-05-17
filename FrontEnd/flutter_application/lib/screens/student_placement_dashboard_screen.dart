import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/placement_service.dart';
import '../models/placement_drive_model.dart';
import '../models/placement_application_model.dart';
import '../models/placement_registration_model.dart';
import '../widgets/student_layout.dart';
import '../widgets/ai_analysis_modal.dart';

class StudentPlacementDashboardScreen extends StatefulWidget {
  final String institutionId;
  const StudentPlacementDashboardScreen({super.key, required this.institutionId});

  @override
  State<StudentPlacementDashboardScreen> createState() => _StudentPlacementDashboardScreenState();
}

class _StudentPlacementDashboardScreenState extends State<StudentPlacementDashboardScreen> {
  bool _isLoading = true;
  UserModel? _currentUser;
  PlacementRegistrationModel? _registration;
  List<PlacementDriveModel> _allDrives = [];
  List<PlacementDriveModel> _filteredDrives = [];
  
  late PlacementService _placementService;
  final ApiService _apiService = ApiService();
  
  String _searchQuery = '';
  double _minSalary = 0;
  String _selectedRole = 'All';
  final List<String> _roles = ['All', 'SDE', 'Data Analyst', 'Product Manager', 'Consultant', 'Designer'];

  @override
  void initState() {
    super.initState();
    _placementService = PlacementService(institutionId: widget.institutionId);
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = await _apiService.getMe(widget.institutionId);
      if (_currentUser != null) {
        _registration = await _placementService.getRegistration(_currentUser!.uid);
        _allDrives = await _placementService.getPlacementDrives();
        _filteredDrives = List.from(_allDrives);
      }
    } catch (e) {
      debugPrint('Error initializing student placement dashboard: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredDrives = _allDrives.where((drive) {
        final matchesSearch = drive.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                             drive.jobRole.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesSalary = drive.salaryPackage >= _minSalary;
        final matchesRole = _selectedRole == 'All' || drive.jobRole.contains(_selectedRole);
        return matchesSearch && matchesSalary && matchesRole;
      }).toList();
    });
  }

  Future<void> _applyForDrive(PlacementDriveModel drive) async {
    if (_registration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please register for placements first!')),
      );
      context.push('/${widget.institutionId}/placement/registration');
      return;
    }

    try {
      await _placementService.applyForDrive(_currentUser!.uid, _currentUser!.displayName, drive.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully applied for ${drive.companyName}!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: 'Placements Dashboard',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Placements', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildRegistrationPrompt(),
                  const SizedBox(height: 24),
                  _buildFilters(),
                  const SizedBox(height: 32),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 1100) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildDrivesList()),
                            const SizedBox(width: 24),
                            Expanded(child: _buildApplicationTracker()),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _buildDrivesList(),
                          const SizedBox(height: 32),
                          _buildApplicationTracker(),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Career Opportunities', 
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('Manage your applications and explore upcoming placement drives', 
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
        Row(
          children: [
            _buildHeaderAction(
              Icons.auto_awesome_rounded, 
              'AI Readiness', 
              () => showDialog(
                context: context,
                builder: (context) => AiAnalysisModal(
                  title: 'Career Readiness Report',
                  subtitle: 'AI-driven placement probability analysis',
                  onAnalyze: () => _apiService.getPlacementReadiness(widget.institutionId),
                ),
              ),
              isAi: true,
            ),
            _buildHeaderAction(
              Icons.description_rounded, 
              'Score Resume', 
              () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'doc', 'docx'],
                );
                if (result != null && result.files.single.bytes != null) {
                  if (!mounted) return;
                  showDialog(
                    context: context,
                    builder: (context) => AiAnalysisModal(
                      title: 'Resume Analysis',
                      subtitle: 'AI-driven resume scoring and feedback',
                      onAnalyze: () => _apiService.getResumeScore(
                        'general', 
                        result.files.single.bytes!, 
                        result.files.single.name
                      ),
                    ),
                  );
                } else if (result != null && result.files.single.path != null) {
                  // Fallback for mobile where bytes might be null but path is available
                  final bytes = await File(result.files.single.path!).readAsBytes();
                  if (!mounted) return;
                  showDialog(
                    context: context,
                    builder: (context) => AiAnalysisModal(
                      title: 'Resume Analysis',
                      subtitle: 'AI-driven resume scoring and feedback',
                      onAnalyze: () => _apiService.getResumeScore(
                        'general', 
                        bytes, 
                        result.files.single.name
                      ),
                    ),
                  );
                }
              }
            ),
            const SizedBox(width: 12),
            _buildHeaderAction(Icons.history_rounded, 'History', () => context.push('/${widget.institutionId}/placement/history')),
            const SizedBox(width: 12),
            _buildHeaderAction(Icons.description_rounded, 'Builder', () => context.push('/${widget.institutionId}/placement/resume-builder')),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderAction(IconData icon, String label, VoidCallback onTap, {bool isAi = false}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: isAi ? Colors.amber : const Color(0xFF4F46E5)),
      label: Text(label, style: TextStyle(color: isAi ? Colors.amber[900] : const Color(0xFF4F46E5))),
      style: ElevatedButton.styleFrom(
        backgroundColor: isAi ? Colors.amber[50] : Colors.white,
        foregroundColor: isAi ? Colors.amber[900] : const Color(0xFF4F46E5),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), 
          side: BorderSide(color: isAi ? Colors.amber.withOpacity(0.3) : const Color(0xFFE5E7EB)),
        ),
      ),
    );
  }

  Widget _buildRegistrationPrompt() {
    if (_registration != null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Placement Registration Pending", style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF92400E), fontSize: 15)),
                Text("You haven't registered for the current season yet. Register now to apply for drives.", 
                  style: TextStyle(color: Color(0xFF92400E), fontSize: 13)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/${widget.institutionId}/placement/registration'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Register Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Search & Filters', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search companies, roles...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (val) {
                    _searchQuery = val;
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedRole = val!);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Min Salary:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF4B5563))),
              const SizedBox(width: 12),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(activeTrackColor: const Color(0xFF4F46E5), thumbColor: const Color(0xFF4F46E5)),
                  child: Slider(
                    value: _minSalary,
                    min: 0,
                    max: 50,
                    divisions: 10,
                    onChanged: (val) {
                      setState(() => _minSalary = val);
                      _applyFilters();
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                child: Text('${_minSalary.toInt()} LPA+', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF4F46E5), fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrivesList() {
    if (_filteredDrives.isEmpty) {
      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No active drives matching your criteria.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return Column(
      children: _filteredDrives.map((drive) => _buildDriveCard(drive)).toList(),
    );
  }

  Widget _buildDriveCard(PlacementDriveModel drive) {
    bool isEligible = _registration != null && 
                     _registration!.cgpa >= drive.minCgpa && 
                     _registration!.backlogCount <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(drive.companyName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                    const SizedBox(height: 4),
                    Text(drive.jobRole, style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.1))),
                child: Text('${drive.salaryPackage} LPA', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1)),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildIconInfo(Icons.calendar_today_rounded, drive.date),
              _buildIconInfo(Icons.location_on_rounded, 'On-Campus'),
              _buildIconInfo(Icons.assignment_ind_rounded, '${drive.minCgpa}+ CGPA Required'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isEligible ? () => _applyForDrive(drive) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade100,
                    disabledForegroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: Text(isEligible ? 'Apply for Position' : 'Not Eligible', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => _showDriveDetails(drive),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
                child: const Icon(Icons.info_outline_rounded, color: Color(0xFF4B5563)),
              ),
            ],
          ),
          if (!isEligible && _registration != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Color(0xFFEF4444)),
                  const SizedBox(width: 6),
                  Text(
                    _registration!.cgpa < drive.minCgpa 
                      ? 'Eligibility: Your CGPA (${_registration!.cgpa}) is below the required ${drive.minCgpa}'
                      : 'Eligibility: 0 active backlogs required.',
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildApplicationTracker() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Application Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5)),
          const SizedBox(height: 20),
          StreamBuilder<List<PlacementApplicationModel>>(
            stream: _placementService.streamStudentApplications(_currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final apps = snapshot.data ?? [];
              if (apps.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.assignment_outlined, size: 40, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text('No active applications', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: apps.map((app) => _buildApplicationStatusTile(app)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationStatusTile(PlacementApplicationModel app) {
    Color statusColor;
    IconData statusIcon;
    switch (app.status.toLowerCase()) {
      case 'selected': statusColor = const Color(0xFF10B981); statusIcon = Icons.check_circle_rounded; break;
      case 'rejected': statusColor = const Color(0xFFEF4444); statusIcon = Icons.cancel_rounded; break;
      case 'shortlisted': statusColor = const Color(0xFF4F46E5); statusIcon = Icons.stars_rounded; break;
      default: statusColor = const Color(0xFFF59E0B); statusIcon = Icons.pending_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(app.companyName, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 6),
                    Text(app.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(app.jobRole, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          Row(
            children: [
              Icon(Icons.account_tree_outlined, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text('Current Stage: ', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              Text(app.currentRound, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
            ],
          ),
        ],
      ),
    );
  }

  void _showDriveDetails(PlacementDriveModel drive) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(drive.companyName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1F2937), letterSpacing: -1)),
                        Text(drive.jobRole, style: const TextStyle(fontSize: 18, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.business_rounded, color: Color(0xFF4F46E5), size: 32),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildDetailSection('About Eligibility', drive.eligibilityCriteria),
              const SizedBox(height: 24),
              _buildDetailSection('Compensation', '${drive.salaryPackage} LPA (Standard Package)'),
              const SizedBox(height: 32),
              const Text('AI Performance Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildAiActionCard(
                      'Skill Gap Analysis', 
                      'Identify missing skills for this role',
                      Icons.psychology_outlined,
                      Colors.blue,
                      () => showDialog(
                        context: context,
                        builder: (context) => AiAnalysisModal(
                          title: 'Skill Gap Analysis',
                          subtitle: 'Comparison with ${drive.companyName} requirements',
                          onAnalyze: () => _apiService.getSkillGapAnalysis(widget.institutionId, drive.id),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAiActionCard(
                      'Profile Match', 
                      'See how well your profile aligns',
                      Icons.fact_check_outlined,
                      Colors.amber,
                      () => showDialog(
                        context: context,
                        builder: (context) => AiAnalysisModal(
                          title: 'Profile Match Report',
                          subtitle: 'Alignment with ${drive.jobRole} position',
                          onAnalyze: () => _apiService.getProfileScore(widget.institutionId, drive.id),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Recruitment Rounds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
              const SizedBox(height: 16),
              ...drive.recruitmentRounds.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                      child: Center(child: Text('${entry.key + 1}', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12))),
                    ),
                    const SizedBox(width: 16),
                    Text(entry.value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF4B5563))),
                  ],
                ),
              )),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3F4F6), foregroundColor: const Color(0xFF1F2937), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  child: const Text('Close Details', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.6)),
      ],
    );
  }

  Widget _buildAiActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
