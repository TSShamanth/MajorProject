import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchProfile() async {
    if (_uid == null) throw Exception('Not logged in');
    return await _firestore.collection('users').doc(_uid).get();
  }

  @override
  Widget build(BuildContext context) {
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
                Text('Student Portal', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF1E293B)),
            onPressed: () async {
              final router = GoRouter.of(context);
              await SessionManager.clearSession();
              await AuthService.logout();
              router.go('/login');
            },
          ),
        ],
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
                  final label = item['label'] as String;
                  if (label == 'Profile') {
                    context.go('/${GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId']}/student/profile');
                  } else if (label == 'Virtual ID') {
                    context.go('/${GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId']}/student/virtual-id');
                  }
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
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: _fetchProfile(),
              builder: (context, snapshot) {
                String name = 'Welcome back';
                String subtitle = '';
                if (snapshot.connectionState == ConnectionState.waiting) {
                  name = 'Welcome back';
                  subtitle = '';
                } else if (snapshot.hasData && snapshot.data!.exists) {
                  final d = snapshot.data!.data();
                  final n = d?['name'] ?? 'Student';
                  final branch = d?['branch'] ?? '';
                  final usn = d?['usn'] ?? '—';
                  name = 'Welcome back, $n';
                  subtitle = '${branch.isNotEmpty ? branch + ' | ' : ''}Roll No: $usn';
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Attendance Card
            _buildAttendanceCard(),
            const SizedBox(height: 24),

            // Quick Access Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: quickAccessItems.length,
              itemBuilder: (context, index) {
                final item = quickAccessItems[index];
                return _buildQuickAccessCard(
                  item['icon'] as IconData,
                  item['label'] as String,
                  item['color'] as Color,
                  onTap: () {
                    final label = (item['label'] as String);
                    if (label == 'Profile') {
                      context.go('/${GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId']}/student/profile');
                    } else if (label == 'Virtual ID') {
                      context.go('/${GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId']}/student/virtual-id');
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Academics Card
            _buildAcademicsCard(),
            const SizedBox(height: 16),
            
            // Events Card
            _buildEventsCard(),
            const SizedBox(height: 16),

            // Placements Card
            _buildPlacementsCard(placementItems),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.indigo.shade600, Colors.indigo.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.bar_chart_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Attendance Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('View your attendance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/${GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId']}/student/attendance'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_forward, color: Colors.indigo, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttendanceStatChip('Total Classes', '20', Colors.white),
                  _buildAttendanceStatChip('Present', '18', Colors.greenAccent),
                  _buildAttendanceStatChip('Absent', '2', Colors.red),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/${GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId']}/student/attendance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.indigo.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('View Detailed Attendance', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: (label == 'Profile')
              ? FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: _fetchProfile(),
                  builder: (context, snapshot) {
                    String name = 'Student';
                    String usn = '—';
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final d = snapshot.data!.data();
                      name = d?['name'] ?? 'Student';
                      usn = d?['usn'] ?? '—';
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14)),
                                  Text(usn, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      ],
                    );
                  },
                )
              : Column(
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
  
  Widget _buildAcademicsCard() {
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
  
  Widget _buildEventsCard() {
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

  Widget _buildPlacementsCard(List<Map<String, String>> items) {
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
                     border: Border.all(color: Colors.grey.shade200)
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Text(item['company']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                       Text(item['role']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                       const SizedBox(height: 4),
                       Text(item['ctc']!, style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                     ],
                   )
                );
              },
            )
          ],
        ),
      ),
    );
  }
}