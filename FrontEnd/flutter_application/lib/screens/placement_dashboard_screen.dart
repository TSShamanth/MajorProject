import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/placement_service.dart';
import '../models/company_model.dart';
import '../models/placement_drive_model.dart';
import '../models/placement_application_model.dart';
import '../models/interview_slot_model.dart';

import '../services/event_service.dart';
import '../models/event_model.dart';

class PlacementDashboardScreen extends StatefulWidget {
  const PlacementDashboardScreen({super.key});

  @override
  State<PlacementDashboardScreen> createState() => _PlacementDashboardScreenState();
}

class _PlacementDashboardScreenState extends State<PlacementDashboardScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isDarkMode = false;
  bool _sidebarExpanded = true;
  bool _isLoading = true;
  UserModel? _currentUser;
  PlacementService? _placementService;
  final EventService _eventService = EventService();
  
  List<CompanyModel> _companies = [];
  List<PlacementDriveModel> _drives = [];
  List<PlacementApplicationModel> _applications = [];
  List<UserModel> _students = [];
  List<EventModel> _events = [];
  List<InterviewSlotModel> _interviewSlots = [];
  Map<String, dynamic> _stats = {};

  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  // Theme Colors
  final Color _accentColor = const Color(0xFF4F46E5);
  Color get _textPrimary => _isDarkMode ? Colors.white : const Color(0xFF1E293B);
  Color get _textSecondary => _isDarkMode ? Colors.white60 : const Color(0xFF64748B);
  Color get _bgColor => _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get _cardColor => _isDarkMode ? const Color(0xFF1E293B) : Colors.white;

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard_rounded, 'label': 'Overview'},
    {'icon': Icons.business_rounded, 'label': 'Companies'},
    {'icon': Icons.campaign_rounded, 'label': 'Recruitment Drives'},
    {'icon': Icons.people_alt_rounded, 'label': 'Student Tracking'},
    {'icon': Icons.group_add_rounded, 'label': 'Master Talent Pool'},
    {'icon': Icons.event_seat_rounded, 'label': 'Interview Logistics'},
    {'icon': Icons.analytics_rounded, 'label': 'Reports'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      final institutionId = GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'];
      if (institutionId != null) {
        _placementService = PlacementService(institutionId: institutionId);
        _currentUser = await _apiService.getMe(institutionId);
        await _fetchAllData(institutionId);
      }
    } catch (e) {
      debugPrint('Error initializing placement dashboard: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAllData([String? institutionId]) async {
    if (_placementService == null) return;
    try {
      final targetInstitutionId = institutionId ?? GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'];
      if (targetInstitutionId == null) return;

      final results = await Future.wait([
        _placementService!.getCompanies(),
        _placementService!.getPlacementDrives(),
        _placementService!.getApplications(),
        _placementService!.getPlacementStats(),
        _apiService.getUsers(targetInstitutionId),
        _eventService.getEventsForAudience(targetInstitutionId, category: 'Placement'),
        _placementService!.getInterviewSlots(),
      ]);

      setState(() {
        _companies = results[0] as List<CompanyModel>;
        _drives = results[1] as List<PlacementDriveModel>;
        _applications = results[2] as List<PlacementApplicationModel>;
        _stats = results[3] as Map<String, dynamic>;
        final allUsers = results[4] as List<UserModel>;
        _students = allUsers.where((u) => u.role?.toLowerCase() == 'student').toList();
        _events = results[5] as List<EventModel>;
        _interviewSlots = results[6] as List<InterviewSlotModel>;
      });
    } catch (e) {
      debugPrint('Error fetching placement data: $e');
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
      backgroundColor: _bgColor,
      drawer: isMobile ? Drawer(child: _buildSidebarContent()) : null,
      body: Row(
        children: [
          if (!isMobile) 
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _sidebarExpanded ? 260 : 80,
              child: _buildSidebarContent(),
            ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isMobile),
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent() {
    return Container(
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          _buildSidebarHeader(),
          const Divider(color: Colors.white10),
          Expanded(child: _buildSidebarMenu()),
          _buildUserCard(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
          ),
          if (_sidebarExpanded) ...[
            const SizedBox(width: 12),
            const Text(
              'Placement Cell',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSidebarMenu() {
    return ListView.builder(
      itemCount: _menuItems.length,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        final isSelected = _selectedIndex == index;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Tooltip(
            message: !_sidebarExpanded ? item['label'] : '',
            child: ListTile(
              onTap: () => setState(() => _selectedIndex = index),
              leading: Icon(item['icon'], color: isSelected ? Colors.white : Colors.white60, size: 22),
              title: _sidebarExpanded 
                ? Text(
                    item['label'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  )
                : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: isSelected ? _accentColor.withOpacity(0.2) : Colors.transparent,
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.all(_sidebarExpanded ? 16 : 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _accentColor,
            child: Text(
              _currentUser?.displayName.isNotEmpty == true ? _currentUser!.displayName[0].toUpperCase() : 'P',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          if (_sidebarExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentUser?.displayName ?? 'Placement Head',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text('Officer', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white60, size: 18),
              onPressed: _handleLogout,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isMobile) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: Icon(Icons.menu, color: _textPrimary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            )
          else
            IconButton(
              icon: Icon(_sidebarExpanded ? Icons.menu_open : Icons.menu, color: _textPrimary),
              onPressed: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
            ),
          const SizedBox(width: 16),
          Text(
            _menuItems[_selectedIndex]['label'],
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textPrimary),
          ),
          const Spacer(),
          if (!isMobile) _buildSearchBar(),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode, color: _textSecondary),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
          const SizedBox(width: 16),
          _buildDateIndicator(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 300,
      height: 40,
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF0F172A) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: const TextStyle(fontSize: 14),
          prefixIcon: Icon(Icons.search, size: 20, color: _textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 8),
        ),
      ),
    );
  }

  Widget _buildDateIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        DateFormat('MMM dd, yyyy').format(DateTime.now()),
        style: TextStyle(color: _accentColor, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (_selectedIndex) {
      case 0: return _buildOverview();
      case 1: return _buildCompanyManagement();
      case 2: return _buildDriveManagement();
      case 3: return _buildStudentTracking();
      case 4: return _buildTalentPool();
      case 5: return _buildInterviewLogistics();
      case 6: return _buildReports();
      default: return const Center(child: Text('Under Construction'));
    }
  }

  // --- TAB METHODS ---

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatCard('Total Companies', _stats['totalCompanies']?.toString() ?? '0', Icons.business, Colors.blue, '+${_stats['newCompaniesMonth'] ?? 0} this month'),
              _buildStatCard('Active Drives', _stats['activeDrives']?.toString() ?? '0', Icons.campaign, Colors.orange, '${_stats['closingSoon'] ?? 0} closing soon'),
              _buildStatCard('Offers Made', _stats['totalOffers']?.toString() ?? '0', Icons.emoji_events, Colors.green, 'High: ${_stats['maxPackage'] ?? 0} LPA'),
              _buildStatCard('Placed %', '${_stats['placedPercentage'] ?? 0}%', Icons.pie_chart, Colors.purple, 'Target: 95%'),
            ],
          ),
          const SizedBox(height: 32),
          Text('Live Recruitment Pipeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(height: 16),
          _buildRecruitmentPipelineChart(),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildRecentDrivesTable()),
              const SizedBox(width: 24),
              Expanded(child: _buildUpcomingEventsCard()),
            ],
          ),
          const SizedBox(height: 32),
          _buildActivityLog(),
        ],
      ),
    );
  }

  Widget _buildActivityLog() {
    // Generate dynamic activity log
    List<Widget> activities = [];
    
    // Recent applications
    final recentApps = _applications.reversed.take(2);
    for (var app in recentApps) {
      activities.add(_buildActivityItem(
        '${app.studentName} applied for ${app.companyName}', 
        'Recently', 
        Icons.person_add, 
        Colors.blue
      ));
    }

    // Recent drives
    final recentDrives = _drives.reversed.take(2);
    for (var drive in recentDrives) {
      activities.add(_buildActivityItem(
        'New recruitment drive launched: ${drive.companyName}', 
        'Recently', 
        Icons.rocket_launch, 
        Colors.green
      ));
    }

    if (activities.isEmpty) {
      activities.add(Center(child: Text('No recent activity', style: TextStyle(color: _textSecondary))));
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Audit & Activity Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 16),
          ...activities,
        ],
      ),
    );
  }

  Widget _buildActivityItem(String message, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: _textPrimary)),
                const SizedBox(height: 2),
                Text(time, style: TextStyle(fontSize: 11, color: _textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtext) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(subtext, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _textPrimary)),
            Text(title, style: TextStyle(color: _textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecruitmentPipelineChart() {
    int totalApps = _applications.length;
    int shortlisted = _applications.where((a) => a.status.toLowerCase() == 'shortlisted').length;
    int technical = _applications.where((a) => a.currentRound.toLowerCase().contains('technical')).length;
    int hr = _applications.where((a) => a.currentRound.toLowerCase().contains('hr')).length;
    int selected = _applications.where((a) => a.status.toLowerCase() == 'selected').length;

    double max = totalApps > 0 ? totalApps.toDouble() : 1.0;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPipelineBar('Applications', totalApps / max, Colors.blue),
          _buildPipelineBar('Shortlisted', shortlisted / max, Colors.orange),
          _buildPipelineBar('Technical', technical / max, Colors.purple),
          _buildPipelineBar('HR Round', hr / max, Colors.green),
          _buildPipelineBar('Offers', selected / max, Colors.amber),
        ],
      ),
    );
  }

  Widget _buildPipelineBar(String label, double value, Color color) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: value > 0 ? (value > 1.0 ? 1.0 : value) : 0.05,
              child: Container(
                width: 40,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _textPrimary)),
      ],
    );
  }

  Widget _buildRecentDrivesTable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Active Drives', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(height: 16),
          if (_drives.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No active drives found', style: TextStyle(color: _textSecondary))),
            )
          else
            Table(
              children: _drives.take(5).map((drive) => _buildTableRow(
                drive.companyName, 
                drive.jobRole, 
                drive.status, 
                '${drive.salaryPackage} LPA'
              )).toList(),
            ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String company, String role, String status, String meta) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(company, style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(role, style: TextStyle(color: _textSecondary))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(status, style: const TextStyle(color: Colors.blueAccent))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(meta, style: TextStyle(color: _textSecondary))),
      ],
    );
  }

  Widget _buildUpcomingEventsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upcoming Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _accentColor)),
          const SizedBox(height: 16),
          if (_events.isEmpty)
             Text('No upcoming placement events', style: TextStyle(color: _textSecondary, fontSize: 13))
          else
            ..._events.take(3).map((e) => _buildEventItem(e.title, e.venue, DateFormat('hh:mm a').format(e.startDateTime))),
        ],
      ),
    );
  }

  Widget _buildEventItem(String title, String location, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 4, height: 30, color: _accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textPrimary)),
                Text('$location • $time', style: TextStyle(color: _textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyManagement() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Company Repository', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textPrimary)),
              ElevatedButton.icon(
                onPressed: _showAddCompanyDialog,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Company Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_companies.isEmpty)
            Expanded(child: Center(child: Text('No companies registered yet', style: TextStyle(color: _textSecondary))))
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.2,
                ),
                itemCount: _companies.length,
                itemBuilder: (context, index) => _buildEnhancedCompanyCard(_companies[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCompanyCard(CompanyModel company) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.business, color: Colors.blueGrey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(company.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textPrimary)),
                    Text('${company.industry} • ${company.tier}', style: TextStyle(color: _textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.star, color: Colors.amber, size: 16),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contact', style: TextStyle(color: _textSecondary, fontSize: 11)),
                  Text(company.hrEmail, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _textPrimary), overflow: TextOverflow.ellipsis),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Website', style: TextStyle(color: _textSecondary, fontSize: 11)),
                  Text(company.website, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddCompanyDialog() {
    final nameController = TextEditingController();
    final industryController = TextEditingController();
    final websiteController = TextEditingController();
    final emailController = TextEditingController();
    final descController = TextEditingController();
    String tier = 'Tier 3';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stfContext, setDialogState) => AlertDialog(
          backgroundColor: _cardColor,
          title: Text('Add New Company', style: TextStyle(color: _textPrimary)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFormTextField('Company Name', Icons.business, controller: nameController),
                  const SizedBox(height: 16),
                  _buildFormTextField('Industry Type', Icons.category, controller: industryController),
                  const SizedBox(height: 16),
                  _buildFormTextField('Official Website', Icons.language, controller: websiteController),
                  const SizedBox(height: 16),
                  _buildFormTextField('HR Contact Email', Icons.email, controller: emailController),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: tier,
                    dropdownColor: _cardColor,
                    style: TextStyle(color: _textPrimary),
                    decoration: const InputDecoration(labelText: 'Company Tier', border: OutlineInputBorder()),
                    items: ['Tier 1', 'Tier 2', 'Tier 3'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setDialogState(() => tier = v!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    style: TextStyle(color: _textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Company Description',
                      labelStyle: TextStyle(color: _textSecondary),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (_placementService == null) return;
                try {
                  final newCompany = CompanyModel(
                    id: '',
                    name: nameController.text,
                    industry: industryController.text,
                    website: websiteController.text,
                    hrEmail: emailController.text,
                    description: descController.text,
                    tier: tier,
                  );
                  await _placementService!.createCompany(newCompany);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _fetchAllData();
                } catch (e) {
                  debugPrint('Error creating company: $e');
                }
              },
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormTextField(String label, IconData icon, {TextEditingController? controller}) {
    return TextField(
      controller: controller,
      style: TextStyle(color: _textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _textSecondary),
        prefixIcon: Icon(icon, size: 20, color: _textSecondary),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDriveManagement() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recruitment Lifecycle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textPrimary)),
              ElevatedButton.icon(
                onPressed: _showCreateDriveStepper,
                icon: const Icon(Icons.rocket_launch, size: 20),
                label: const Text('Launch Recruitment Drive'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_drives.isEmpty)
            Expanded(child: Center(child: Text('No recruitment drives launched yet', style: TextStyle(color: _textSecondary))))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _drives.length,
                itemBuilder: (context, index) => _buildDriveCard(_drives[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDriveCard(PlacementDriveModel drive) {
    Color statusColor;
    switch (drive.status.toLowerCase()) {
      case 'active': statusColor = Colors.green; break;
      case 'completed': statusColor = Colors.blue; break;
      default: statusColor = Colors.grey;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          final institutionId = GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'];
          if (institutionId != null) {
            context.push('/$institutionId/placement/drive/${drive.id}');
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.work_outline, color: statusColor),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(drive.jobRole, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
                    Text(drive.companyName, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Eligibility: ${drive.minCgpa}+ CGPA • ${drive.allowedDepartments.join(", ")}', style: TextStyle(color: _textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(drive.date, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textPrimary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(drive.status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              _buildDriveActionMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriveActionMenu() {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert, color: _textSecondary),
      itemBuilder: (context) => [
        const PopupMenuItem(child: ListTile(leading: Icon(Icons.edit), title: Text('Edit Drive'))),
        const PopupMenuItem(child: ListTile(leading: Icon(Icons.people), title: Text('View Applicants'))),
        const PopupMenuItem(child: ListTile(leading: Icon(Icons.notifications), title: Text('Broadcast Alert'))),
      ],
    );
  }

  void _showCreateDriveStepper() {
    if (_placementService == null) return;
    showDialog(
      context: context,
      builder: (context) => _CreateDriveStepperDialog(
        service: _placementService!,
        companies: _companies,
        onComplete: () => _fetchAllData(),
      ),
    );
  }

  Widget _buildStudentTracking() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recruitment Progress Tracking', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textPrimary)),
              Row(
                children: [
                  _buildFilterChip('All Students', true),
                  const SizedBox(width: 8),
                  _buildFilterChip('Shortlisted', false),
                  const SizedBox(width: 8),
                  _buildFilterChip('Selected', false),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_applications.isEmpty)
            Expanded(child: Center(child: Text('No student applications found', style: TextStyle(color: _textSecondary))))
          else
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(_accentColor.withOpacity(0.05)),
                      columns: const [
                        DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Company', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Current Round', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _applications.map((app) => _buildDataRow(app)).toList(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.blueGrey)),
      selected: isSelected,
      selectedColor: _accentColor,
      onSelected: (val) {},
    );
  }

  DataRow _buildDataRow(PlacementApplicationModel app) {
    Color statusColor;
    switch (app.status.toLowerCase()) {
      case 'shortlisted': statusColor = Colors.blue; break;
      case 'selected': statusColor = Colors.green; break;
      case 'rejected': statusColor = Colors.red; break;
      default: statusColor = Colors.orange;
    }

    return DataRow(cells: [
      DataCell(Text(app.studentName, style: TextStyle(fontWeight: FontWeight.w600, color: _textPrimary))),
      DataCell(Text(app.companyName, style: TextStyle(color: _textSecondary))),
      DataCell(Text(app.currentRound, style: TextStyle(color: _textSecondary))),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(app.status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
      DataCell(
        TextButton(
          onPressed: () => _showUpdateStatusDialog(app),
          child: const Text('Update Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    ]);
  }

  void _showUpdateStatusDialog(PlacementApplicationModel app) {
    String selectedRound = app.currentRound;
    String selectedStatus = app.status;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stfContext, setDialogState) => AlertDialog(
          backgroundColor: _cardColor,
          title: Text('Update Progress: ${app.studentName}', style: TextStyle(color: _textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedRound,
                dropdownColor: _cardColor,
                style: TextStyle(color: _textPrimary),
                decoration: const InputDecoration(labelText: 'Move to Round'),
                items: ['Aptitude', 'Technical 1', 'Technical 2', 'HR Round', 'Offer Made']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedRound = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: ['Applied', 'Shortlisted', 'Selected', 'Rejected'].contains(selectedStatus) ? selectedStatus : 'Applied',
                dropdownColor: _cardColor,
                style: TextStyle(color: _textPrimary),
                decoration: const InputDecoration(labelText: 'Result/Status'),
                items: ['Applied', 'Shortlisted', 'Selected', 'Rejected'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setDialogState(() => selectedStatus = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (_placementService == null) return;
                try {
                  await _placementService!.updateApplicationStatus(app.id, selectedStatus, selectedRound);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _fetchAllData();
                } catch (e) {
                  debugPrint('Error updating application status: $e');
                }
              },
              child: const Text('Update Status'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTalentPool() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Master Talent Pool', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textPrimary)),
                  Text('Database of all 1,240 registered students', style: TextStyle(color: _textSecondary, fontSize: 13)),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.file_upload_outlined),
                    label: const Text('Bulk Sync ERP'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_for_offline_outlined),
                    label: const Text('Export CSV'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withOpacity(0.1))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by USN, Name, or Skills...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildFilterButton('Branch: All'),
                const SizedBox(width: 12),
                _buildFilterButton('CGPA: > 7.0'),
                const SizedBox(width: 12),
                _buildFilterButton('Backlogs: 0'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Talent Table
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.1))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(_accentColor.withOpacity(0.05)),
                    columns: const [
                      DataColumn(label: Text('Student Detail')),
                      DataColumn(label: Text('Branch')),
                      DataColumn(label: Text('USN')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _students.map((student) => _buildTalentRow(
                      student.displayName, 
                      student.usn ?? 'N/A', 
                      student.programme ?? 'N/A', 
                      'Active', 
                      true
                    )).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildTalentRow(String name, String usn, String branch, String status, bool verified) {
    return DataRow(cells: [
      DataCell(Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary)),
          Text(usn, style: TextStyle(fontSize: 11, color: _textSecondary)),
        ],
      )),
      DataCell(Text(branch)),
      DataCell(Text(usn, style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: verified ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
        child: Text(verified ? 'Verified' : 'Pending', style: TextStyle(color: verified ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
      )),
      DataCell(Row(
        children: [
          IconButton(icon: const Icon(Icons.visibility_outlined, size: 18), onPressed: () {}),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () {}),
        ],
      )),
    ]);
  }

  Widget _buildFilterButton(String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.filter_list, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
    );
  }

  Widget _buildInterviewLogistics() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Interview Day Logistics Manager', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textPrimary)),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Interview Slot'),
                style: ElevatedButton.styleFrom(backgroundColor: _accentColor, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildLogisticsPanel('Panel 1 (Tech)', 'Room 302', 'Amazon', 'Ongoing', Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLogisticsPanel('Panel 2 (Tech)', 'Room 303', 'Amazon', 'Waiting', Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLogisticsPanel('Panel 3 (HR)', 'Room 304', 'Google', 'Scheduled', Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Upcoming Interview Slots', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.1))),
              child: _interviewSlots.isEmpty 
                ? Center(child: Text('No upcoming interviews scheduled', style: TextStyle(color: _textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _interviewSlots.length,
                    itemBuilder: (context, index) {
                      final slot = _interviewSlots[index];
                      String timeStr = 'N/A';
                      try {
                        timeStr = DateFormat('hh:mm a').format(DateTime.parse(slot.dateTime));
                      } catch (e) {
                        // Keep default 'N/A' if parsing fails
                      }
                      return _buildSlotTile(
                        timeStr, 
                        slot.studentName, 
                        '${slot.companyName} - ${slot.roundName}', 
                        slot.panelName
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsPanel(String panelName, String room, String company, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(panelName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(room, style: TextStyle(color: _textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.business_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(company, style: TextStyle(color: _textSecondary, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlotTile(String time, String studentName, String contextDesc, String panel) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: _accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(time.split(' - ')[0], style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
      title: Text(studentName, style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary)),
      subtitle: Text('$contextDesc • $panel', style: TextStyle(color: _textSecondary)),
      trailing: IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
    );
  }

  Widget _buildReports() {
    // Calculate department stats
    Map<String, int> deptTotal = {};
    Map<String, int> deptPlaced = {};
    
    for (var student in _students) {
      String dept = student.programme ?? 'Other';
      deptTotal[dept] = (deptTotal[dept] ?? 0) + 1;
    }
    
    for (var app in _applications) {
      if (app.status.toLowerCase() == 'selected') {
        var student = _students.firstWhere((s) => s.uid == app.studentUid, orElse: () => UserModel(uid: '', email: '', displayName: '', role: ''));
        if (student.uid.isNotEmpty) {
          String dept = student.programme ?? 'Other';
          deptPlaced[dept] = (deptPlaced[dept] ?? 0) + 1;
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Placement Intelligence & Analytics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textPrimary)),
              ElevatedButton.icon(
                onPressed: () {}, 
                icon: const Icon(Icons.picture_as_pdf), 
                label: const Text('Export Season Report'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Row 1: Dynamic Department Stats
          if (deptTotal.isEmpty)
             Center(child: Text('No department data available', style: TextStyle(color: _textSecondary)))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: deptTotal.entries.map((entry) {
                  double percent = entry.value > 0 ? (deptPlaced[entry.key] ?? 0) / entry.value : 0;
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 16),
                    child: _buildDepartmentStat(entry.key, percent, _accentColor),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Salary Distribution
              Expanded(
                flex: 2,
                child: _buildSalaryHeatmap(),
              ),
              const SizedBox(width: 24),
              // Right: Recruitment Funnel
              Expanded(
                child: _buildRecruitmentFunnel(),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildMonthlyTrendChart(),
        ],
      ),
    );
  }

  Widget _buildDepartmentStat(String dept, double percent, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 60,
                  width: 60,
                  child: CircularProgressIndicator(value: percent, strokeWidth: 8, backgroundColor: color.withOpacity(0.1), color: color),
                ),
                Text('${(percent * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            Text(dept, style: TextStyle(fontWeight: FontWeight.bold, color: _textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryHeatmap() {
    int superDream = 0; // > 20
    int dream = 0;      // 10 - 20
    int mass = 0;       // 5 - 10
    int other = 0;      // < 5

    for (var app in _applications) {
      if (app.status.toLowerCase() == 'selected') {
        var drive = _drives.firstWhere((d) => d.companyName == app.companyName && d.jobRole == app.jobRole, orElse: () => PlacementDriveModel(id: '', companyId: '', companyName: '', jobRole: '', salaryPackage: 0, date: '', status: '', eligibilityCriteria: '', minCgpa: 0, allowedDepartments: [], recruitmentRounds: []));
        if (drive.salaryPackage >= 20) {
          superDream++;
        } else if (drive.salaryPackage >= 10) {
          dream++;
        } else if (drive.salaryPackage >= 5) {
          mass++;
        } else {
          other++;
        }
      }
    }

    int totalPlaced = superDream + dream + mass + other;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Salary Package Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(height: 24),
          _buildSalaryBar('Super Dream (> 20 LPA)', superDream, Colors.purple, totalPlaced),
          _buildSalaryBar('Dream (10 - 20 LPA)', dream, Colors.blue, totalPlaced),
          _buildSalaryBar('Mass (5 - 10 LPA)', mass, Colors.green, totalPlaced),
          _buildSalaryBar('Other (< 5 LPA)', other, Colors.orange, totalPlaced),
        ],
      ),
    );
  }

  Widget _buildSalaryBar(String label, int count, Color color, int total) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: _textSecondary)),
              Text('$count Students', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: total > 0 ? count / total : 0, 
            backgroundColor: color.withOpacity(0.1), 
            color: color, 
            minHeight: 8, 
            borderRadius: BorderRadius.circular(4)
          ),
        ],
      ),
    );
  }

  Widget _buildRecruitmentFunnel() {
    int totalEligible = _students.length;
    int applied = _applications.map((e) => e.studentUid).toSet().length;
    int shortlisted = _applications.where((a) => a.status.toLowerCase() == 'shortlisted').map((e) => e.studentUid).toSet().length;
    int offered = _applications.where((a) => a.status.toLowerCase() == 'selected').map((e) => e.studentUid).toSet().length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recruitment Funnel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(height: 24),
          _buildFunnelStep('Total Eligible', totalEligible.toString(), 1.0, Colors.grey),
          _buildFunnelStep('Applied', applied.toString(), totalEligible > 0 ? applied / totalEligible : 0, Colors.blue),
          _buildFunnelStep('Shortlisted', shortlisted.toString(), applied > 0 ? shortlisted / applied : 0, Colors.orange),
          _buildFunnelStep('Offered', offered.toString(), shortlisted > 0 ? offered / shortlisted : 0, Colors.green),
        ],
      ),
    );
  }

  Widget _buildFunnelStep(String label, String value, double width, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Container(
            height: 40,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
                Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey[300]),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendChart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Recruitment Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(height: 40),
          const Center(child: Icon(Icons.stacked_line_chart, size: 120, color: Colors.blueAccent)),
          const SizedBox(height: 20),
          Center(child: Text('Recruitment velocity increased by 15% compared to last year', style: TextStyle(color: _textSecondary, fontSize: 13))),
        ],
      ),
    );
  }
}

class _CreateDriveStepperDialog extends StatefulWidget {
  final PlacementService service;
  final List<CompanyModel> companies;
  final VoidCallback onComplete;

  const _CreateDriveStepperDialog({
    required this.service,
    required this.companies,
    required this.onComplete,
  });

  @override
  State<_CreateDriveStepperDialog> createState() => _CreateDriveStepperDialogState();
}

class _CreateDriveStepperDialogState extends State<_CreateDriveStepperDialog> {
  int _currentStep = 0;
  CompanyModel? _selectedCompany;
  final _roleController = TextEditingController();
  final _salaryController = TextEditingController();
  final _cgpaController = TextEditingController();
  final _deptController = TextEditingController();
  final _criteriaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Launch Recruitment Drive'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) setState(() => _currentStep++);
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
          },
          steps: [
            Step(
              title: const Text('Basic Info'),
              content: Column(
                children: [
                  DropdownButtonFormField<CompanyModel>(
                    decoration: const InputDecoration(labelText: 'Select Company', border: OutlineInputBorder()),
                    items: widget.companies.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                    onChanged: (val) => setState(() => _selectedCompany = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: _roleController, decoration: const InputDecoration(labelText: 'Job Role (e.g. SDE-1)', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: _salaryController, decoration: const InputDecoration(labelText: 'Salary Package (LPA)', border: OutlineInputBorder())),
                ],
              ),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Eligibility Criteria'),
              content: Column(
                children: [
                  TextField(controller: _cgpaController, decoration: const InputDecoration(labelText: 'Minimum CGPA (e.g. 7.5)', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: _deptController, decoration: const InputDecoration(labelText: 'Allowed Departments (e.g. CS, IT)', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: _criteriaController, maxLines: 2, decoration: const InputDecoration(labelText: 'Other Criteria', border: OutlineInputBorder())),
                ],
              ),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Recruitment Rounds'),
              content: const Column(
                children: [
                  Text('Rounds defined for this drive:'),
                  SizedBox(height: 12),
                  CheckboxListTile(value: true, onChanged: null, title: Text('Aptitude Test')),
                  CheckboxListTile(value: true, onChanged: null, title: Text('Technical Round 1')),
                  CheckboxListTile(value: true, onChanged: null, title: Text('Final HR Interview')),
                ],
              ),
              isActive: _currentStep >= 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        if (_currentStep == 2) 
          ElevatedButton(
            onPressed: () async {
              if (_selectedCompany == null) return;
              try {
                final newDrive = PlacementDriveModel(
                  id: '',
                  companyId: _selectedCompany!.id,
                  companyName: _selectedCompany!.name,
                  jobRole: _roleController.text,
                  salaryPackage: double.tryParse(_salaryController.text) ?? 0.0,
                  date: DateFormat('MMM dd, yyyy').format(DateTime.now()),
                  status: 'Active',
                  eligibilityCriteria: _criteriaController.text,
                  minCgpa: double.tryParse(_cgpaController.text) ?? 0.0,
                  allowedDepartments: _deptController.text.split(',').map((e) => e.trim()).toList(),
                  recruitmentRounds: ['Aptitude', 'Technical 1', 'HR Round'],
                );
                await widget.service.createDrive(newDrive);
                widget.onComplete();
                if (!context.mounted) return;
                Navigator.pop(context);
              } catch (e) {
                debugPrint('Error creating drive: $e');
              }
            }, 
            child: const Text('Publish Drive')
          ),
      ],
    );
  }
}
// For re-pushing the commits