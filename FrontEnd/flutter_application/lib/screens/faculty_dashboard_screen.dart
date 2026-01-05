
import 'package:flutter/material.dart';

class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen> {
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
    final menuItems = [
      {'icon': Icons.person_outline, 'label': 'Profile', 'description': 'View personal details'},
      {'icon': Icons.credit_card_outlined, 'label': 'Virtual ID', 'description': 'Access faculty ID card'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Timetable', 'description': 'View teaching schedule'},
      {'icon': Icons.group_outlined, 'label': 'Mentees', 'description': 'View assigned students'},
      {'icon': Icons.description_outlined, 'label': 'Leave', 'description': 'Apply for leave'},
      {'icon': Icons.attach_money, 'label': 'Payroll', 'description': 'View salary slips'},
      {'icon': Icons.celebration_outlined, 'label': 'Events', 'description': 'Create & manage events'},
      {'icon': Icons.notifications_none_outlined, 'label': 'Meetings', 'description': 'Faculty meetings'}
    ];

    final quickAccessItems = [
      {'icon': Icons.calendar_today_outlined, 'label': 'Timetable', 'color': Colors.blue},
      {'icon': Icons.group_outlined, 'label': 'Mentees', 'color': Colors.purple},
      {'icon': Icons.attach_money, 'label': 'Payroll', 'color': Colors.green},
      {'icon': Icons.description_outlined, 'label': 'Leave', 'color': Colors.orange}
    ];

    final scheduleItems = [
      {'time': '09:00 AM', 'class': 'CSE-A', 'subject': 'Data Structures', 'room': 'Lab 301'},
      {'time': '11:00 AM', 'class': 'CSE-B', 'subject': 'Algorithms', 'room': 'Room 205'},
      {'time': '02:00 PM', 'class': 'CSE-C', 'subject': 'DBMS', 'room': 'Lab 302'}
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
                Text('Faculty Portal', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
            const Text('Welcome, Dr. Priya Sharma', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const Text('Computer Science Department | Faculty ID: FAC2021', style: TextStyle(color: Colors.grey)),
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
                return _buildQuickAccessCard(item['icon'] as IconData, item['label'] as String, item['color'] as Color);
              },
            ),
            const SizedBox(height: 24),

            // Today's Schedule
            _buildTodaysScheduleCard(scheduleItems),
            const SizedBox(height: 16),
            
            // Mentees Overview
            _buildMenteesOverviewCard(),
            const SizedBox(height: 16),

            // Payroll Summary
            _buildPayrollSummaryCard(),
            const SizedBox(height: 16),

            // Events & Meetings
            _buildEventsMeetingsCard(),

            // Leave Status
            const SizedBox(height: 16),
            _buildLeaveStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard() {
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
                    Text('95%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text('This month', style: TextStyle(color: Colors.grey)),
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
  
  Widget _buildTodaysScheduleCard(List<Map<String, String>> items) {
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
                  child: const Icon(Icons.calendar_today_outlined, color: Color(0xFF1E293B)),
                ),
                const SizedBox(width: 12),
                const Text('Today\'s Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['time']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Chip(
                            label: Text(item['class']!),
                            backgroundColor: Colors.blue.shade100,
                            labelStyle: TextStyle(color: Colors.blue.shade800, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(item['subject']!, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14)),
                      Text(item['room']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenteesOverviewCard() {
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
                  child: const Icon(Icons.group_outlined, color: Color(0xFF1E293B)),
                ),
                const SizedBox(width: 12),
                const Text('Mentees Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Mentees', style: TextStyle(color: Colors.grey)),
                Text('24', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Excellent (90% +)', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    Text('12', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade600, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Good (75-90%)', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    Text('8', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade600, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Needs Attention', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    Text('4', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade600, fontSize: 14)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('View All Mentees', style: TextStyle(color: Color(0xFF1E293B))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayrollSummaryCard() {
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
                  child: const Icon(Icons.attach_money, color: Color(0xFF1E293B)),
                ),
                const SizedBox(width: 12),
                const Text('Payroll', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Month Salary', style: TextStyle(color: Colors.green, fontSize: 14)),
                  Text('₹85,000', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Basic Pay', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        Text('₹60,000', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Allowances', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        Text('₹25,000', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('View Salary Slip', style: TextStyle(color: Color(0xFF1E293B))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsMeetingsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    const Text('Events & Meetings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('+ Create Event', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Faculty Meeting', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                          Chip(
                            label: const Text('Tomorrow'),
                            backgroundColor: Colors.purple.shade200,
                            labelStyle: TextStyle(color: Colors.purple.shade800, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('10:00 AM | Conference Hall', style: TextStyle(color: Colors.purple.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tech Workshop', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          Chip(
                            label: const Text('Jan 10'),
                            backgroundColor: Colors.blue.shade200,
                            labelStyle: TextStyle(color: Colors.blue.shade800, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Organized by: You', style: TextStyle(color: Colors.blue.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveStatusCard() {
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
                  child: const Icon(Icons.description_outlined, color: Color(0xFF1E293B)),
                ),
                const SizedBox(width: 12),
                const Text('Leave Balance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 12),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200)
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('12', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const Text('Casual Leave', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200)
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('5', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const Text('Optional Holidays', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200)
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('8', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const Text('Sick Leave', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
