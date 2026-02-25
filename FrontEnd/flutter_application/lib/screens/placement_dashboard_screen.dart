import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class PlacementDashboardScreen extends StatefulWidget {
  const PlacementDashboardScreen({super.key});

  @override
  State<PlacementDashboardScreen> createState() => _PlacementDashboardScreenState();
}

class _PlacementDashboardScreenState extends State<PlacementDashboardScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isDarkMode = false;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard_rounded, 'label': 'Overview'},
    {'icon': Icons.business_rounded, 'label': 'Companies'},
    {'icon': Icons.campaign_rounded, 'label': 'Recruitment Drives'},
    {'icon': Icons.people_alt_rounded, 'label': 'Student Tracking'},
    {'icon': Icons.analytics_rounded, 'label': 'Reports'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
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

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
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
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Placement Cell',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService.logout();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
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
          child: ListTile(
            onTap: () => setState(() => _selectedIndex = index),
            leading: Icon(item['icon'], color: isSelected ? Colors.white : Colors.white60, size: 22),
            title: Text(
              item['label'],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
        final item = items[index];
        bool active = item['active'] == true;

        return InkWell(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: active ? _accentColor.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  item['icon'] as IconData, 
                  color: active ? _accentColor : Colors.white60, 
                  size: 22
                ),
                if (_sidebarExpanded) ...[
                  const SizedBox(width: 16),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white60,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Placement Head',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                Text('Admin Access', style: TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white60, size: 18),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Text(
            _menuItems[_selectedIndex]['label'],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          _buildSearchBar(),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
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
        decoration: const InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(fontSize: 14),
          prefixIcon: Icon(Icons.search, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(top: 8),
        ),
      ),
    );
  }

  Widget _buildDateIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        DateFormat('MMM dd, yyyy').format(DateTime.now()),
        style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return _buildOverview();
      case 1: return _buildCompanyManagement();
      case 2: return _buildDriveManagement();
      case 3: return _buildStudentTracking();
      case 4: return _buildReports();
      default: return const Center(child: Text('Under Construction'));
    }
  }

  // --- 0. OVERVIEW TAB ---
  Widget _buildOverview() {
  Widget _buildTopBarActions() {
    return Row(
      children: [
        IconButton(
          icon: Icon(_isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: _textSecondary),
          onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
        ),
        const SizedBox(width: 12),
        if (MediaQuery.of(context).size.width > 1024)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_currentUser?.displayName ?? 'Placement Officer', style: TextStyle(fontWeight: FontWeight.w700, color: _textPrimary, fontSize: 14)),
              Text('Placement Cell', style: TextStyle(color: _textSecondary, fontSize: 12)),
            ],
          ),
        const SizedBox(width: 12),
        PopupMenuButton<String>(
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'logout') {
              _handleLogout();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 20),
                  SizedBox(width: 12),
                  Text('My Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: Colors.redAccent.shade200, size: 20),
                  const SizedBox(width: 12),
                  const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                ],
              ),
            ),
          ],
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded, color: _accentColor),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatCard('Total Companies', '42', Icons.business, Colors.blue, '+3 this month'),
              _buildStatCard('Active Drives', '12', Icons.campaign, Colors.orange, '4 closing soon'),
              _buildStatCard('Offers Made', '156', Icons.emoji_events, Colors.green, 'High: 45 LPA'),
              _buildStatCard('Placed %', '78%', Icons.pie_chart, Colors.purple, 'Target: 95%'),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Live Recruitment Pipeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildRecruitmentPipelineChart(),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(flex: 2, child: _buildRecentDrivesTable()),
              const SizedBox(width: 24),
              Expanded(child: _buildUpcomingEventsCard()),
            ],
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
          color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
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
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecruitmentPipelineChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPipelineBar('Applications', 0.9, Colors.blue),
          _buildPipelineBar('Aptitude', 0.65, Colors.orange),
          _buildPipelineBar('Technical', 0.4, Colors.purple),
          _buildPipelineBar('HR Round', 0.25, Colors.green),
          _buildPipelineBar('Offers', 0.15, Colors.amber),
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
              heightFactor: value,
              child: Container(
                width: 40,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRecentDrivesTable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Active Drives', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Table(
            children: [
              _buildTableRow('Microsoft', 'SDE-1', 'Aptitude', '85 Apps'),
              _buildTableRow('Google', 'SDE-Intrn', 'Shortlist', '120 Apps'),
              _buildTableRow('Amazon', 'SDE-1', 'HR Round', '45 Apps'),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String company, String role, String status, String meta) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(company, style: const TextStyle(fontWeight: FontWeight.bold))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(role)),
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(status, style: const TextStyle(color: Colors.blueAccent))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(meta, style: const TextStyle(color: Colors.grey))),
      ],
    );
  }

  Widget _buildUpcomingEventsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upcoming Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          const SizedBox(height: 16),
          _buildEventItem('Pre-Placement Talk', 'Google', '10:00 AM'),
          _buildEventItem('Mock Interview', 'Dept CS', '02:00 PM'),
          _buildEventItem('Coding Contest', 'CodeChef', '06:00 PM'),
        ],
      ),
    );
  }

  Widget _buildEventItem(String title, String location, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 4, height: 30, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('$location • $time', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. COMPANIES TAB ---
  Widget _buildCompanyManagement() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Company Repository', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _showAddCompanyDialog,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Company Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
              ),
              itemCount: 9,
              itemBuilder: (context, index) => _buildEnhancedCompanyCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCompanyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Google India', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Technology • Tier 1', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.star, color: Colors.amber, size: 16),
            ],
          ),
          const Spacer(),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Drives', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  Text('02', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Avg Package', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  Text('18.5 LPA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddCompanyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Company'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFormTextField('Company Name', Icons.business),
                const SizedBox(height: 16),
                _buildFormTextField('Industry Type', Icons.category),
                const SizedBox(height: 16),
                _buildFormTextField('Official Website', Icons.language),
                const SizedBox(height: 16),
                _buildFormTextField('HR Contact Email', Icons.email),
                const SizedBox(height: 16),
                _buildFormTextField('Base Salary (LPA)', Icons.payments),
                const SizedBox(height: 16),
                const TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Company Description',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save Profile')),
        ],
      ),
    );
  }

  Widget _buildFormTextField(String label, IconData icon) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // --- 2. DRIVE MANAGEMENT TAB ---
  Widget _buildDriveManagement() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recruitment Lifecycle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
          _buildDriveCard('Software Development Engineer', 'Amazon India', 'Feb 15, 2026', 'Round 2: Technical', Colors.blue, 'Eligibility: 8.0+ CGPA'),
          _buildDriveCard('Data Science Intern', 'Zomato', 'Feb 20, 2026', 'Registration Open', Colors.green, 'Eligibility: CS/IT Only'),
          _buildDriveCard('Systems Architect', 'Intel', 'Mar 05, 2026', 'Draft', Colors.grey, 'Incomplete details'),
        ],
      ),
    );
  }

  Widget _buildDriveCard(String role, String company, String date, String status, Color statusColor, String eligibility) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
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
                Text(role, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(company, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(eligibility, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(width: 24),
          _buildDriveActionMenu(),
        ],
      ),
    );
  }

  Widget _buildDriveActionMenu() {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      itemBuilder: (context) => [
        const PopupMenuItem(child: ListTile(leading: Icon(Icons.edit), title: Text('Edit Drive'))),
        const PopupMenuItem(child: ListTile(leading: Icon(Icons.people), title: Text('View Applicants'))),
        const PopupMenuItem(child: ListTile(leading: Icon(Icons.notifications), title: Text('Broadcast Alert'))),
      ],
    );
  }

  void _showCreateDriveStepper() {
    showDialog(
      context: context,
      builder: (context) => const _CreateDriveStepperDialog(),
    );
  }

  // --- 3. STUDENT TRACKING TAB ---
  Widget _buildStudentTracking() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recruitment Progress Tracking', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.blueAccent.withOpacity(0.05)),
                    columns: const [
                      DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Company', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Current Round', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: [
                      _buildDataRow('Alice Smith', 'Google', 'Technical Round 2', 'Shortlisted', Colors.blue),
                      _buildDataRow('Bob Johnson', 'Amazon', 'Aptitude Test', 'In-Progress', Colors.orange),
                      _buildDataRow('Charlie Brown', 'Microsoft', 'Final HR', 'Selected', Colors.green),
                      _buildDataRow('David Miller', 'Google', 'Technical Round 1', 'Rejected', Colors.red),
                      _buildDataRow('Eve Adams', 'Zomato', 'Application', 'Pending', Colors.grey),
                    ],
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
      selectedColor: Colors.blueAccent,
      onSelected: (val) {},
    );
  }

  DataRow _buildDataRow(String name, String company, String round, String status, Color color) {
    return DataRow(cells: [
      DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
      DataCell(Text(company)),
      DataCell(Text(round)),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
      DataCell(
        TextButton(
          onPressed: () => _showUpdateStatusDialog(name),
          child: const Text('Update Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    ]);
  }

  void _showUpdateStatusDialog(String studentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Progress: $studentName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Move to Round'),
              items: ['Aptitude', 'Technical 1', 'Technical 2', 'HR Round', 'Offer Made']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {},
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Result'),
              items: ['Pass', 'Fail', 'Hold'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Update Status')),
        ],
      ),
    );
  }

  // --- 4. REPORTS TAB ---
  Widget _buildReports() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Institutional Placement Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildChartPlaceholder('Department-wise Placement')),
              const SizedBox(width: 24),
              Expanded(child: _buildChartPlaceholder('Salary Package Distribution')),
            ],
          ),
          const SizedBox(height: 24),
          _buildChartPlaceholder('Monthly Recruitment Trend (2025-26)'),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder(String title) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          const Center(child: Icon(Icons.bar_chart, size: 100, color: Colors.blueAccent)),
          const Spacer(),
          const Center(child: Text('Analytics Data Visualization Module', style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }
}

// --- SUB-WIDGET: DRIVE CREATION STEPPER ---
class _CreateDriveStepperDialog extends StatefulWidget {
  const _CreateDriveStepperDialog();

  @override
  State<_CreateDriveStepperDialog> createState() => _CreateDriveStepperDialogState();
}

class _CreateDriveStepperDialogState extends State<_CreateDriveStepperDialog> {
  int _currentStep = 0;

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
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select Company'),
                    items: ['Google', 'Amazon', 'Microsoft'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) {},
                  ),
                  const SizedBox(height: 16),
                  const TextField(decoration: InputDecoration(labelText: 'Job Role (e.g. SDE-1)')),
                  const SizedBox(height: 16),
                  const TextField(decoration: InputDecoration(labelText: 'Salary Package (LPA)')),
                ],
              ),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Eligibility Criteria'),
              content: Column(
                children: [
                  const TextField(decoration: InputDecoration(labelText: 'Minimum CGPA (e.g. 7.5)')),
                  const SizedBox(height: 16),
                  const TextField(decoration: InputDecoration(labelText: 'Max Active Backlogs')),
                  const SizedBox(height: 16),
                  const TextField(decoration: InputDecoration(labelText: 'Allowed Departments (CS, IT, EC)')),
                ],
              ),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Recruitment Rounds'),
              content: const Column(
                children: [
                  Text('Define the rounds for this drive:'),
                  SizedBox(height: 12),
                  CheckboxListTile(value: true, onChanged: null, title: Text('Aptitude Test')),
                  CheckboxListTile(value: true, onChanged: null, title: Text('Technical Round 1')),
                  CheckboxListTile(value: false, onChanged: null, title: Text('Coding Contest')),
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
        if (_currentStep == 2) ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Publish Drive')),
      ],
    );
  }
}
