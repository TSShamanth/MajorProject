import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/placement_service.dart';
import '../models/placement_drive_model.dart';
import '../models/placement_application_model.dart';
import '../models/placement_registration_model.dart';

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
        SnackBar(content: Text('Successfully applied for ${drive.companyName}!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Placements', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push('/${widget.institutionId}/placement/history'),
            tooltip: 'Placement History',
          ),
          IconButton(
            icon: const Icon(Icons.description_rounded),
            onPressed: () => context.push('/${widget.institutionId}/placement/resume-builder'),
            tooltip: 'Resume Builder',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildRegistrationPrompt(),
          _buildFilters(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildDrivesList()),
                Expanded(flex: 2, child: _buildApplicationTracker()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationPrompt() {
    if (_registration != null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "You haven't registered for the current placement season yet.",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/${widget.institutionId}/placement/registration'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: const Text('Register Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search companies or roles...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (val) {
                    _searchQuery = val;
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedRole,
                items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) {
                  setState(() => _selectedRole = val!);
                  _applyFilters();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Min Salary: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Slider(
                  value: _minSalary,
                  min: 0,
                  max: 50,
                  divisions: 10,
                  label: '${_minSalary.toInt()} LPA',
                  onChanged: (val) {
                    setState(() => _minSalary = val);
                    _applyFilters();
                  },
                ),
              ),
              Text('${_minSalary.toInt()} LPA'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrivesList() {
    if (_filteredDrives.isEmpty) {
      return const Center(child: Text('No active drives matching your criteria.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredDrives.length,
      itemBuilder: (context, index) => _buildDriveCard(_filteredDrives[index]),
    );
  }

  Widget _buildDriveCard(PlacementDriveModel drive) {
    bool isEligible = _registration != null && 
                     _registration!.cgpa >= drive.minCgpa && 
                     _registration!.backlogCount <= 0; // Assuming 0 backlogs required for now

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(drive.companyName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(drive.jobRole, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('${drive.salaryPackage} LPA', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              _buildInfoChip(Icons.calendar_today, 'Date: ${drive.date}'),
              const SizedBox(width: 16),
              _buildInfoChip(Icons.location_on, 'Location: On-Campus'),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoChip(Icons.assignment_ind, 'Eligibility: ${drive.minCgpa}+ CGPA, 0 Backlogs'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isEligible ? () => _applyForDrive(drive) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(isEligible ? 'Apply Now' : 'Not Eligible'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => _showDriveDetails(drive),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                child: const Text('Details'),
              ),
            ],
          ),
          if (!isEligible && _registration != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _registration!.cgpa < drive.minCgpa 
                  ? 'Criteria unmet: Your CGPA (${_registration!.cgpa}) is lower than ${drive.minCgpa}'
                  : 'Criteria unmet: 0 backlogs required.',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
    );
  }

  Widget _buildApplicationTracker() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Application Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<PlacementApplicationModel>>(
              stream: _placementService.streamStudentApplications(_currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final apps = snapshot.data ?? [];
                if (apps.isEmpty) {
                  return const Center(child: Text('No applications yet.', style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) => _buildApplicationStatusTile(apps[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationStatusTile(PlacementApplicationModel app) {
    Color statusColor;
    switch (app.status.toLowerCase()) {
      case 'selected': statusColor = Colors.green; break;
      case 'rejected': statusColor = Colors.red; break;
      case 'shortlisted': statusColor = Colors.blue; break;
      default: statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(app.companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(app.status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(app.jobRole, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.layers_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('Round: ${app.currentRound}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text(drive.companyName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(drive.jobRole, style: TextStyle(fontSize: 18, color: Colors.grey[700])),
              const SizedBox(height: 24),
              _buildDetailSection('About the Role', drive.eligibilityCriteria), // Reuse field for description if needed
              const SizedBox(height: 24),
              _buildDetailSection('Salary Details', '${drive.salaryPackage} LPA Fixed + Performance Bonus'),
              const SizedBox(height: 24),
              const Text('Selection Process', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...drive.recruitmentRounds.map((round) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Text(round, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              )),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
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
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
      ],
    );
  }
}
