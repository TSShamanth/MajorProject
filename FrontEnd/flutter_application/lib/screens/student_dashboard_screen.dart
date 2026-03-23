import 'package:flutter/material.dart';
import 'package:flutter_application/models/course_model.dart';
import 'package:flutter_application/models/time_slot_model.dart';
import 'package:flutter_application/models/timetable_entry_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/attendance_service.dart';
import 'package:flutter_application/services/timetable_service.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_layout.dart';
import '../widgets/ai_insight_modal.dart';
import 'dart:math' as math;

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<TimetableEntry> _todaySchedule = [];
  List<TimeSlot> _allTimeSlots = [];
  List<Course> _allCourses = [];
  UserModel? _user;
  Map<String, dynamic>? _academicSummary;
  bool _isLoadingSchedule = true;
  bool _isLoadingSummary = true;
  double _attendancePercentage = 0.0;
  String? _institutionId;

  Future<void> _fetchTodaySchedule() async {
    final institutionId = _getInstitutionId();
    if (institutionId.isEmpty) return;

    try {
      final timetableService = TimetableService();
      final apiService = ApiService();
      
      final user = await apiService.getMe(institutionId);
      if (mounted) {
        setState(() {
          _user = user;
          _attendancePercentage = user.attendancePercentage ?? 0.0;
          _institutionId = institutionId;
        });
      }
      if (user.departmentId == null || user.programme == null || user.sem == null || user.sectionId == null) {
        if (mounted) {
          setState(() {
            _isLoadingSchedule = false;
            _isLoadingSummary = false;
          });
        }
        return;
      }

      _fetchAcademicSummary(institutionId, user.uid);

      final now = DateTime.now();
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final todayName = days[now.weekday - 1];
      debugPrint('Student Dashboard: Fetching schedule for $todayName');

      final results = await Future.wait([
        timetableService.getTimeSlots(institutionId),
        timetableService.getTimetableForClass(institutionId, user.departmentId!, user.programme!, user.sem!, user.sectionId!),
        apiService.getCourses(institutionId, user.departmentId!),
        apiService.getRooms(institutionId),
      ]);

      final slots = results[0] as List<TimeSlot>;
      final allEntries = results[1] as List<TimetableEntry>;
      final courses = results[2] as List<Course>;

      final todayEntries = allEntries.where((e) => e.day == todayName).toList();
      
      todayEntries.sort((a, b) {
        final slotA = slots.indexWhere((s) => s.id == a.timeSlotId);
        final slotB = slots.indexWhere((s) => s.id == b.timeSlotId);
        return slotA.compareTo(slotB);
      });

      if (mounted) {
        setState(() {
          _allTimeSlots = slots;
          _todaySchedule = todayEntries;
          _allCourses = courses;
          _user = user;
          _isLoadingSchedule = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching today schedule: $e');
      if (mounted) {
        setState(() {
          _isLoadingSchedule = false;
          _isLoadingSummary = false;
        });
      }
    }
  }

  Future<void> _fetchAcademicSummary(String institutionId, String studentId) async {
    try {
      final apiService = ApiService();
      final results = await Future.wait([
        apiService.getAcademicSummary(institutionId, studentId),
        AttendanceService.getSubjectWiseAttendance(studentId),
      ]);

      if (mounted) {
        final attendanceData = results[1] as List<dynamic>;
        double totalPct = 0;
        if (attendanceData.isNotEmpty) {
          for (var item in attendanceData) {
            totalPct += (item.attendancePercentage as num).toDouble();
          }
          _attendancePercentage = totalPct / attendanceData.length;
        }

        setState(() {
          _academicSummary = results[0] as Map<String, dynamic>;
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching academic summary: $e');
      if (mounted) {
        setState(() => _isLoadingSummary = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTodaySchedule();
    });
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  String _getInstitutionId() {
    return GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'route': '/student/dashboard'},
      {'icon': Icons.person_outline_rounded, 'label': 'My Profile', 'route': '/student/profile'},
      {'icon': Icons.supervisor_account_rounded, 'label': 'My Mentor', 'route': '/student/my-mentors'},
      {'icon': Icons.credit_card_rounded, 'label': 'Virtual ID', 'route': '/student/virtual-id'},
      {'icon': Icons.schedule_rounded, 'label': 'Timetable', 'route': '/student/timetable'},
      {'icon': Icons.article_outlined, 'label': 'My Hall Tickets', 'route': '/student/hall-tickets'},
      {'icon': Icons.menu_book_rounded, 'label': 'Academic Records', 'route': '/student/academics'},
      {'icon': Icons.assignment_rounded, 'label': 'Assignments & Tasks', 'route': '/student/academics'},
      {'icon': Icons.event_busy_rounded, 'label': 'Leave', 'route': '/student/leave'},
      {'icon': Icons.calendar_today_rounded, 'label': 'Events & Calendar', 'route': '/events'},
      {'icon': Icons.business_center_rounded, 'label': 'Placements', 'route': '/student/placement'},
      {'icon': Icons.campaign_rounded, 'label': 'Announcements', 'route': '/announcements'},
      {'icon': Icons.message_rounded, 'label': 'Messages', 'route': '/student/messages'},
      {'icon': Icons.payment_rounded, 'label': 'Fees', 'route': '/student/fees'},
      {'icon': Icons.edit_note_rounded, 'label': 'Study Planner', 'route': '/student/study-planner'},
      {'icon': Icons.notes_rounded, 'label': 'Notes', 'route': '/student/notes'},
      {'icon': Icons.description_outlined, 'label': 'Surveys & Forms', 'route': '/student/forms'}
    ];

    return AppLayout(
      userRole: 'Student',
      userDisplayName: _user?.displayName ?? 'Student',
      userSubTitle: _user?.programme ?? 'Undergraduate',
      avatarText: _user?.displayName != null && _user!.displayName.isNotEmpty ? _user!.displayName[0].toUpperCase() : 'S',
      menuItems: menuItems,
      institutionId: _institutionId,
      child: _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width < 1024;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              _buildResponsiveStatsRow(isMobile, isTablet),
              const SizedBox(height: 24),
              _buildProgressRingsCard(),
              const SizedBox(height: 24),
              _buildResponsiveMainContent(isMobile, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, ${_user?.displayName ?? 'Student'}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Here\'s your academic and placement overview',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Material(
          color: const Color(0xFF4F46E5).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const AiInsightModal(),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFF4F46E5), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'AI Insights',
                    style: TextStyle(
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveStatsRow(bool isMobile, bool isTablet) {
    if (isMobile) {
      return Column(
        children: [
          _buildStatCard('Current Semester', _user?.sem ?? 'N/A', _user?.programme ?? 'B.Tech CSE', Icons.menu_book_rounded, const Color(0xFF4F46E5)),
          const SizedBox(height: 12),
          _buildStatCard('CGPA', _user?.currentGPA?.toStringAsFixed(1) ?? '8.6', 'Current Standing', Icons.trending_up_rounded, const Color(0xFF10B981)),
          const SizedBox(height: 12),
          _buildStatCard('Pending Tasks', '5', '2 Assignments, 3 Tests', Icons.assignment_rounded, const Color(0xFFF59E0B)),
          const SizedBox(height: 12),
          _buildStatCard('Active Applications', '8', '3 Pending Reviews', Icons.business_center_rounded, const Color(0xFF8B5CF6)),
        ],
      );
    }
    
    return Row(
      children: [
        Expanded(child: _buildStatCard('Current Semester', _user?.sem ?? 'N/A', _user?.programme ?? 'B.Tech CSE', Icons.menu_book_rounded, const Color(0xFF4F46E5))),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('CGPA', _user?.currentGPA?.toStringAsFixed(1) ?? '8.6', 'Current Standing', Icons.trending_up_rounded, const Color(0xFF10B981))),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Pending Tasks', '5', '2 Assignments, 3 Tests', Icons.assignment_rounded, const Color(0xFFF59E0B))),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Active Applications', '8', '3 Pending Reviews', Icons.business_center_rounded, const Color(0xFF8B5CF6))),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtext, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF6B7280).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRingsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.donut_large_rounded, color: Color(0xFF4F46E5), size: 20),
              SizedBox(width: 12),
              Text(
                'Progress Overview',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressRing('Attendance', _attendancePercentage, const Color(0xFF10B981)),
              _buildProgressRing('Assignments', (_academicSummary?['assignmentsPercentage'] as num?)?.toDouble() ?? 0.0, const Color(0xFF4F46E5)),
              _buildProgressRing('Credits', (_academicSummary?['creditsPercentage'] as num?)?.toDouble() ?? 0.0, const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing(String label, double percentage, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CustomPaint(
            painter: _ProgressRingPainter(percentage: percentage, color: color),
            child: Center(
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveMainContent(bool isMobile, bool isTablet) {
    if (isMobile) {
      return Column(
        children: [
          _buildTodaySchedule(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
          const SizedBox(height: 24),
          _buildQuickActions(),
        ],
      );
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildTodaySchedule(),
              const SizedBox(height: 24),
              _buildRecentActivity(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildAcademicProgress(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySchedule() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: Color(0xFF10B981), size: 18),
                  SizedBox(width: 10),
                  Text(
                    'Today\'s Schedule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View Full Timetable', style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingSchedule)
            const Center(child: CircularProgressIndicator())
          else if (_todaySchedule.isEmpty)
            const Center(child: Text('No classes scheduled for today.'))
          else
            ..._todaySchedule.map((entry) {
              final slot = _allTimeSlots.firstWhere((s) => s.id == entry.timeSlotId);
              final course = _allCourses.firstWhere((c) => c.courseCode == entry.courseCode, orElse: () => Course(courseCode: '', courseName: 'Unknown', facultyUid: '', institutionId: '', program: '', semester: '', studentsEnrolled: [], totalClasses: ''));
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(course.courseName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                          const SizedBox(height: 4),
                          Text('${slot.startTime} - ${slot.endTime} • Room ${entry.roomId}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      {'title': 'Assignment Submitted', 'subtitle': 'Data Structures - Lab 5', 'time': '2h ago', 'icon': Icons.check_circle_rounded, 'color': const Color(0xFF10B981)},
      {'title': 'New Placement Drive', 'subtitle': 'Google - Software Engineer', 'time': '5h ago', 'icon': Icons.business_center_rounded, 'color': const Color(0xFF4F46E5)},
      {'title': 'Attendance Warning', 'subtitle': 'Computer Networks - 72%', 'time': '1d ago', 'icon': Icons.warning_rounded, 'color': const Color(0xFFF59E0B)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
          const SizedBox(height: 16),
          ...activities.map((activity) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (activity['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(activity['icon'] as IconData, color: activity['color'] as Color, size: 18),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                      Text(activity['subtitle'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                Text(activity['time'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'label': 'My Mentor', 'icon': Icons.supervisor_account_rounded, 'color': const Color(0xFFEC4899)},
      {'label': 'Virtual ID', 'icon': Icons.credit_card_rounded, 'color': const Color(0xFF4F46E5)},
      {'label': 'Fees', 'icon': Icons.payment_rounded, 'color': const Color(0xFFF59E0B)},
      {'label': 'Events', 'icon': Icons.calendar_today_rounded, 'color': const Color(0xFF10B981)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: actions.map((action) => InkWell(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (action['color'] as Color).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (action['color'] as Color).withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(action['icon'] as IconData, color: action['color'] as Color, size: 18),
                    const SizedBox(width: 8),
                    Text(action['label'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicProgress() {
    if (_isLoadingSummary) return const Center(child: CircularProgressIndicator());
    
    final stats = [
      {'label': 'Assignments', 'value': '${_academicSummary?['assignmentsCompleted'] ?? 0}/${_academicSummary?['assignmentsTotal'] ?? 5}', 'color': const Color(0xFF10B981)},
      {'label': 'Tests', 'value': '${_academicSummary?['testsAttempted'] ?? 0}/${_academicSummary?['testsTotal'] ?? 3}', 'color': const Color(0xFF4F46E5)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Academic Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
          const SizedBox(height: 16),
          ...stats.map((stat) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(stat['label'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                    Text(stat['value'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: stat['color'] as Color)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.7, // Placeholder
                  backgroundColor: const Color(0xFFF3F4F6),
                  valueColor: AlwaysStoppedAnimation(stat['color'] as Color),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double percentage;
  final Color color;

  _ProgressRingPainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(center, radius - 4, backgroundPaint);
    
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * math.pi * (percentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
