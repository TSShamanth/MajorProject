import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Data is currently mocked here. In a real app, you would get this 
    // from a state management solution (Bloc, Riverpod, Provider).
    final menuItems = [
      {'icon': Icons.person_outline, 'label': 'Profile', 'description': 'View personal details'},
      {'icon': Icons.credit_card_outlined, 'label': 'Virtual ID', 'description': 'Access student ID card'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Timetable', 'description': 'View class schedule'},
      {'icon': Icons.menu_book_outlined, 'label': 'Academics', 'description': 'Semester & subjects'},
      {'icon': Icons.description_outlined, 'label': 'Leave', 'description': 'Apply & track leave'},
      {'icon': Icons.celebration_outlined, 'label': 'Events', 'description': 'Register for events'},
      {'icon': Icons.business_center_outlined, 'label': 'Placements', 'description': 'View opportunities'}
    ];

    final quickAccessItems = [
      {'icon': Icons.person_outline, 'label': 'Profile', 'color': Colors.blue},
      {'icon': Icons.credit_card_outlined, 'label': 'Virtual ID', 'color': Colors.purple},
      {'icon': Icons.calendar_today_outlined, 'label': 'Timetable', 'color': Colors.green},
      {'icon': Icons.description_outlined, 'label': 'Leave', 'color': Colors.orange}
    ];

    final placementItems = [
      {'company': 'Google', 'role': 'SDE Intern', 'ctc': '₹8L'},
      {'company': 'Microsoft', 'role': 'Software Engineer', 'ctc': '₹12L'},
      {'company': 'Amazon', 'role': 'SDE-1', 'ctc': '₹10L'}
    ];
    
    final announcementItems = [
      'Mid-term exams for Semester 6 are scheduled from Feb 10th.',
      'Registrations for the annual Tech Fest are now open.',
      'Submit your project proposals by Jan 25th.'
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(menuItems),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _WelcomeHeader(),
            const SizedBox(height: 24),
            _AttendanceCard(),
            const SizedBox(height: 24),
            _QuickAccessGrid(items: quickAccessItems),
            const SizedBox(height: 24),
            _AnnouncementsCard(items: announcementItems),
            const SizedBox(height: 16),
            const _AcademicsCard(),
            const SizedBox(height: 16),
            const _EventsCard(),
            const SizedBox(height: 16),
            _PlacementsCard(items: placementItems),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
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
              Text('Student Portal', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF1E293B)),
          onPressed: () async {
            await AuthService.logout();
          },
        ),
      ],
    );
  }

  Drawer _buildDrawer(List<Map<String, Object>> menuItems) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF1E293B),
            ),
            child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          for (var item in menuItems)
            ListTile(
              leading: Icon(item['icon'] as IconData, color: const Color(0xFF1E293B)),
              title: Text(item['label'] as String),
              subtitle: Text(item['description'] as String),
              onTap: () {
                // Navigator.pop(context); // Context is not available in a StatelessWidget build method directly
              },
            ),
        ],
      ),
    );
  }
}

// --- Welcome Header Widget ---
class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back, Rohan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        Text('CSE-B | Roll No: 21CS001', style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}

// --- Attendance Card Widget ---
class _AttendanceCard extends StatefulWidget {
  @override
  State<_AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<_AttendanceCard> {
  bool _isAttendanceLoggedIn = false;
  String? _attendanceTime;

  void _handleAttendanceLogin() {
    setState(() {
      _isAttendanceLoggedIn = true;
      _attendanceTime = TimeOfDay.now().format(context);
    });
  }

  void _handleAttendanceLogout() {
    setState(() {
      _isAttendanceLoggedIn = false;
      _attendanceTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on_outlined, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text('Location-based verification', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('87%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text('This semester', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isAttendanceLoggedIn ? _buildLoggedInView() : _buildLoggedOutView(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedOutView() {
    return ElevatedButton.icon(
      onPressed: _handleAttendanceLogin,
      icon: const Icon(Icons.access_time_outlined, color: Colors.white),
      label: const Text('Login Attendance', style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLoggedInView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            border: Border.all(color: Colors.green.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Logged In', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              Text(_attendanceTime ?? '', style: const TextStyle(color: Colors.green)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _handleAttendanceLogout,
          icon: const Icon(Icons.logout, color: Color(0xFF1E293B)),
          label: const Text('Logout Attendance', style: TextStyle(color: Color(0xFF1E293B))),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.grey.shade200,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

// --- Quick Access Grid Widget ---
class _QuickAccessGrid extends StatelessWidget {
  final List<Map<String, Object>> items;
  const _QuickAccessGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildQuickAccessCard(item['icon'] as IconData, item['label'] as String, item['color'] as Color);
      },
    );
  }

  Widget _buildQuickAccessCard(IconData icon, String label, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Announcements Card Widget (New Inclusion) ---
class _AnnouncementsCard extends StatelessWidget {
  final List<String> items;
  const _AnnouncementsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.campaign_outlined, color: Color(0xFF1E293B)),
                ),
                const SizedBox(width: 12),
                const Text('Announcements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 8, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: const TextStyle(color: Colors.black87))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// --- Academics Card Widget ---
class _AcademicsCard extends StatelessWidget {
  const _AcademicsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu_book_outlined, color: Color(0xFF1E293B)),
                ),
                const SizedBox(width: 12),
                const Text('Academics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Semester', style: TextStyle(color: Colors.grey)), Text('6th', style: TextStyle(fontWeight: FontWeight.bold))],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Credits', style: TextStyle(color: Colors.grey)), Text('22', style: TextStyle(fontWeight: FontWeight.bold))],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Mentor', style: TextStyle(color: Colors.grey)), Text('Dr. Sharma', style: TextStyle(fontWeight: FontWeight.bold))],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Events Card Widget ---
class _EventsCard extends StatelessWidget {
  const _EventsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.celebration_outlined, color: Color(0xFF1E293B)),
                ),
                const SizedBox(width: 12),
                const Text('Upcoming Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tech Fest 2025', style: TextStyle(color: Colors.grey)),
                Chip(
                  label: const Text('Jan 15'),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: TextStyle(color: Colors.blue.shade800, fontSize: 12),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Hackathon', style: TextStyle(color: Colors.grey)),
                Chip(
                  label: const Text('Jan 20'),
                  backgroundColor: Colors.green.shade50,
                  labelStyle: TextStyle(color: Colors.green.shade800, fontSize: 12),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Placements Card Widget ---
class _PlacementsCard extends StatelessWidget {
  final List<Map<String, String>> items;
  const _PlacementsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business_center_outlined, color: Color(0xFF1E293B)),
                ),
                const SizedBox(width: 12),
                const Text('Placement Opportunities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
      
                      children: [
                        Text(item['company']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(item['role']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(item['ctc']!, style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ));
              },
            )
          ],
        ),
      ),
    );
  }
}
