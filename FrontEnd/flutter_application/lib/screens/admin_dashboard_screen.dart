
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {'icon': Icons.business_outlined, 'label': 'Institution', 'description': 'Manage institution settings'},
      {'icon': Icons.person_add_alt_1_outlined, 'label': 'User Management', 'description': 'Create & manage users'},
      {'icon': Icons.bar_chart_outlined, 'label': 'Attendance Reports', 'description': 'View attendance analytics'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Academic Calendar', 'description': 'Manage timetables & holidays'},
      {'icon': Icons.business_center_outlined, 'label': 'Placements', 'description': 'Manage placement drives'},
      {'icon': Icons.celebration_outlined, 'label': 'Events', 'description': 'Oversee all events'},
      {'icon': Icons.analytics_outlined, 'label': 'Analytics', 'description': 'Institution-wide reports'},
      {'icon': Icons.settings_outlined, 'label': 'Settings', 'description': 'System configuration'}
    ];

    final stats = [
      {'label': 'Total Students', 'value': '1,248', 'change': '+12%', 'color': Colors.blue},
      {'label': 'Total Faculty', 'value': '84', 'change': '+3%', 'color': Colors.purple},
      {'label': 'Avg Attendance', 'value': '87%', 'change': '+2%', 'color': Colors.green},
      {'label': 'Active Placements', 'value': '15', 'change': '+5', 'color': Colors.orange}
    ];

    final quickActions = [
      {'icon': Icons.person_add_alt_1_outlined, 'label': 'Add User', 'color': Colors.blue},
      {'icon': Icons.business_outlined, 'label': 'Institution Setup', 'color': Colors.purple},
      {'icon': Icons.business_center_outlined, 'label': 'New Placement', 'color': Colors.green},
      {'icon': Icons.calendar_today_outlined, 'label': 'Add Holiday', 'color': Colors.orange}
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Acadexa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                Text('Admin Portal', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF1E293B),
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            for (var item in menuItems)
              ListTile(
                leading: Icon(item['icon'] as IconData, color: const Color(0xFF1E293B)),
                title: Text(item['label'] as String),
                subtitle: Text(item['description'] as String),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome, Admin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const Text('VIT Chennai | Administrator', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // Stats Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.0,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                final stat = stats[index];
                return _buildStatCard(stat['label'] as String, stat['value'] as String, stat['change'] as String, stat['color'] as Color);
              },
            ),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActionsCard(quickActions),
            const SizedBox(height: 24),

            // User Management
            _buildUserManagementCard(),
            const SizedBox(height: 16),

            // Attendance Analytics
            _buildAttendanceAnalyticsCard(),
            const SizedBox(height: 16),

            // Placement Drives
            _buildPlacementDrivesCard(),
            const SizedBox(height: 16),
            
            // Academic Management
            _buildAcademicManagementCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String change, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(change, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(List<Map<String, Object>> actions) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(action['icon'] as IconData, color: action['color'] as Color),
                  label: Text(action['label'] as String, style: const TextStyle(color: Color(0xFF1E293B))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (action['color'] as Color).withOpacity(0.1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagementCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.group_outlined),
                    SizedBox(width: 8),
                    Text('User Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton(onPressed: () {}, child: const Text('+ Add User')),
              ],
            ),
            const SizedBox(height: 16),
            _buildUserTypeTile('Students', '1,248', 'Active accounts', Colors.blue),
            const SizedBox(height: 8),
            _buildUserTypeTile('Faculty', '84', 'Active accounts', Colors.purple),
            const SizedBox(height: 8),
            _buildUserTypeTile('Admins', '3', 'System administrators', Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeTile(String title, String count, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              Text(subtitle, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
            ],
          ),
          Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildAttendanceAnalyticsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart_outlined),
                SizedBox(width: 8),
                Text('Attendance Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressRow('CSE Department', '89%', 0.89, Colors.blue),
            _buildProgressRow('ECE Department', '85%', 0.85, Colors.purple),
            _buildProgressRow('MECH Department', '83%', 0.83, Colors.green),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
              child: const Text('View Detailed Reports'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, String value, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacementDrivesCard() {
    final drives = [
      {'company': 'Google India', 'applicants': '145 students registered', 'status': 'Active', 'color': Colors.green},
      {'company': 'Microsoft', 'applicants': '89 students registered', 'status': 'Shortlisting', 'color': Colors.blue},
      {'company': 'Amazon', 'applicants': '203 students registered', 'status': 'Active', 'color': Colors.green}
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.business_center_outlined),
                    SizedBox(width: 8),
                    Text('Placement Drives', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton(onPressed: () {}, child: const Text('+ Create Drive')),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: drives.map((drive) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (drive['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: (drive['color'] as Color).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(drive['company'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Chip(
                              label: Text(drive['status'] as String),
                              backgroundColor: Colors.white,
                              labelStyle: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(drive['applicants'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicManagementCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today_outlined),
                SizedBox(width: 8),
                Text('Academic Calendar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoTile('Upcoming Holiday', 'Republic Day', 'Jan 26', Colors.orange),
            const SizedBox(height: 8),
            _buildInfoTile('Semester End', 'Spring 2025', 'Apr 30', Colors.purple),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('Add Holiday'))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('Manage Timetable'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String subtitle, String trailing, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
            ],
          ),
          Chip(backgroundColor: color.withOpacity(0.3), label: Text(trailing)),
        ],
      ),
    );
  }
}
