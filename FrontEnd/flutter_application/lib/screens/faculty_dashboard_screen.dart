import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int notifications = 8;

  final List<Map<String, dynamic>> menuItems = [
    {'icon': Icons.home, 'label': 'Dashboard', 'active': true},
    {'icon': Icons.people_outline, 'label': 'Student Management', 'badge': '8'},
    {'icon': Icons.book_outlined, 'label': 'Course Management'},
    {'icon': Icons.assignment_outlined, 'label': 'Assignments & Grading'},
    {'icon': Icons.work_outline, 'label': 'Placement Tracking'},
    {'icon': Icons.calendar_today, 'label': 'Schedule Management'},
    {'icon': Icons.trending_up, 'label': 'Reports & Analytics'},
    {'icon': Icons.message_outlined, 'label': 'Communication'},
    {'icon': Icons.settings_outlined, 'label': 'Settings'},
  ];

  final List<Map<String, dynamic>> quickActions = [
    {'label': 'Grade Assignments', 'icon': Icons.assignment_outlined},
    {'label': 'Schedule Class', 'icon': Icons.calendar_today},
    {'label': 'Approve Student Profiles', 'icon': Icons.person_outline},
    {'label': 'View Student Reports', 'icon': Icons.trending_up},
    {'label': 'Post Announcements', 'icon': Icons.message_outlined},
    {'label': 'Manage Courses', 'icon': Icons.book_outlined},
  ];

  final List<Map<String, dynamic>> statsCards = [
    {
      'title': 'My Courses',
      'value': '4',
      'icon': Icons.book_outlined,
      'color': const Color(0xFF3B82F6),
      'trend': '142 Students',
      'trendUp': false,
    },
    {
      'title': 'Pending Evaluations',
      'value': '28',
      'icon': Icons.assignment_outlined,
      'color': const Color(0xFFF59E0B),
      'trend': '3 Assignments',
      'trendUp': false,
    },
    {
      'title': 'Mentee Placements',
      'value': '76%',
      'icon': Icons.work_outline,
      'color': const Color(0xFF10B981),
      'trend': '32/42 Placed',
      'trendUp': true,
    },
    {
      'title': 'Classes This Week',
      'value': '6',
      'icon': Icons.calendar_today,
      'color': const Color(0xFF8B5CF6),
      'trend': '18 Hours',
      'trendUp': false,
    },
  ];

  final List<Map<String, String>> upcomingEvents = [
    {
      'title': 'Grade CS301 Assignments',
      'date': 'Today',
      'time': '5:00 PM',
      'type': 'task',
      'priority': 'high'
    },
    {
      'title': 'Advanced Algorithms Lecture',
      'date': 'Tomorrow',
      'time': '2:00 PM',
      'type': 'class',
      'priority': 'high'
    },
    {
      'title': 'Student Profile Approvals',
      'date': 'Tomorrow',
      'time': '4:00 PM',
      'type': 'task',
      'priority': 'medium'
    },
    {
      'title': 'Placement Drive Coordination',
      'date': 'Jan 16, 2026',
      'time': '9:00 AM',
      'type': 'meeting',
      'priority': 'high'
    },
    {
      'title': 'Department Faculty Meeting',
      'date': 'Jan 17, 2026',
      'time': '11:00 AM',
      'type': 'meeting',
      'priority': 'medium'
    },
    {
      'title': 'Data Structures Lab Session',
      'date': 'Jan 18, 2026',
      'time': '10:00 AM',
      'type': 'class',
      'priority': 'medium'
    },
    {
      'title': 'Mid-Term Exam Invigilation',
      'date': 'Jan 20, 2026',
      'time': '2:00 PM',
      'type': 'exam',
      'priority': 'high'
    },
    {
      'title': 'Research Paper Review',
      'date': 'Jan 22, 2026',
      'time': '3:00 PM',
      'type': 'task',
      'priority': 'low'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),
      drawer: _buildDrawer(),
      body: CustomScrollView(
        slivers: [
          // Header as Sliver AppBar
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            toolbarHeight: 48,
            leading: IconButton(
              icon: const Icon(Icons.menu, size: 18, color: Color(0xFF374151)),
              padding: EdgeInsets.zero,
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: Row(
              children: [
                const Text(
                  'AcadWorkHub',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                        prefixIcon: Icon(Icons.search, size: 14, color: Color(0xFF9CA3AF)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                offset: const Offset(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 12),
                    ],
                  ),
                ),
                itemBuilder: (context) => quickActions.map((action) {
                  return PopupMenuItem<String>(
                    value: action['label'] as String,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        Icon(action['icon'] as IconData, size: 14, color: const Color(0xFF6B7280)),
                        const SizedBox(width: 8),
                        Text(
                          action['label'] as String,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 6),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 16, color: Color(0xFF6B7280)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {},
                  ),
                  if (notifications > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '$notifications',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Color(0xFF4F46E5),
                    child: Text(
                      'PS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Welcome Banner
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back, Dr. Sharma!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Associate Professor - Computer Science Department',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Home',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      const Text(
                        'Dashboard',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Dashboard Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildStatsCards(),
                  const SizedBox(height: 12),
                  _buildUpcomingSchedule(),
                  // Add extra spacing to push footer below fold
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                ],
              ),
            ),
          ),
          
          // Footer - appears only when scrolled
          SliverToBoxAdapter(
            child: _buildFooter(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 260,
      child: Container(
        color: const Color(0xFF312E81),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF4C1D95)),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  final isActive = item['active'] == true;
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF4C1D95) : Colors.transparent,
                      border: isActive
                          ? const Border(
                              left: BorderSide(color: Colors.white, width: 3),
                            )
                          : null,
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: Icon(
                        item['icon'] as IconData,
                        color: Colors.white,
                        size: 16,
                      ),
                      title: Text(
                        item['label'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      trailing: item['badge'] != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['badge'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF4C1D95)),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help & Support',
                    style: TextStyle(
                      color: Color(0xFFC4B5FD),
                      fontSize: 10,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Documentation',
                    style: TextStyle(
                      color: Color(0xFFC4B5FD),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.0,
          ),
          itemCount: statsCards.length,
          itemBuilder: (context, index) {
            final card = statsCards[index];
            return _buildStatCard(card);
          },
        );
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> card) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Value at TOP
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (card['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  card['icon'] as IconData,
                  color: card['color'] as Color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                card['value'] as String,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  height: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Title and Trend at BOTTOM
          Text(
            card['title'] as String,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF6B7280),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                (card['trendUp'] as bool) ? Icons.arrow_upward : Icons.arrow_downward,
                size: 8,
                color: (card['trendUp'] as bool) ? const Color(0xFF10B981) : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  card['trend'] as String,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Color(0xFF6B7280),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSchedule() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: const Color(0xFF4F46E5),
                  size: 14,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Upcoming Schedule & Tasks',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;
                  
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: upcomingEvents.length,
                    itemBuilder: (context, index) {
                      return _buildEventCard(upcomingEvents[index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, String> event) {
    Color getTypeColor(String type) {
      switch (type) {
        case 'task':
          return const Color(0xFFF59E0B);
        case 'class':
          return const Color(0xFF3B82F6);
        case 'meeting':
          return const Color(0xFF10B981);
        case 'exam':
          return const Color(0xFFEF4444);
        default:
          return const Color(0xFF8B5CF6);
      }
    }

    final typeColor = getTypeColor(event['type']!);
    
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF9FAFB), Color(0xFFF3F4F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge and Priority
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  event['type']!,
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (event['priority'] == 'high')
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Title
          Expanded(
            child: Text(
              event['title']!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          // Date and Time
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 9,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 4),
              Text(
                event['date']!,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            event['time']!,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2026 AcadWorkHub. All rights reserved.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _buildFooterLink('📱 Download App'),
              _buildFooterLink('✉️ Contact Us'),
              _buildFooterLink('Privacy Policy'),
              _buildFooterLink('Terms'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return GestureDetector(
      onTap: () {},
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
} 