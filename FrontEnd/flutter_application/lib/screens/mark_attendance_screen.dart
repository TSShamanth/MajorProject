import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';
import '../services/session_manager.dart';
import '../services/auth_service.dart';
import 'package:go_router/go_router.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  // ── Business logic state (unchanged) ──────────────────────────────────────
  List<Course> _courses = [];
  List<UserModel> _students = [];
  List<UserModel> _filteredStudents = [];
  Course? _selectedCourse;
  DateTime _selectedDate = DateTime.now();
  Map<String, bool> _attendanceMap = {};
  Map<String, String> _remarksMap = {};
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _institutionId;
  String? _facultyUid;

  // ── Shell state ────────────────────────────────────────────────────────────
  bool _sidebarExpanded = true;
  bool _isDarkMode = false;

  // ── Theme helpers ──────────────────────────────────────────────────────────
  Color get _bgColor =>
      _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
  Color get _cardColor =>
      _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
  Color get _textPrimary =>
      _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
  Color get _textSecondary =>
      _isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get _borderColor =>
      _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

  static const _accent  = Color(0xFF4F46E5);
  static const _success = Color(0xFF10B981);
  static const _danger  = Color(0xFFEF4444);
  static const _warning = Color(0xFFF59E0B);

  // ── Lifecycle (unchanged) ──────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    _institutionId = await SessionManager.getInstitutionId();
    _facultyUid =
        firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (_institutionId == null || _facultyUid == null) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Could not retrieve institution or faculty ID.';
        });
      }
      return;
    }
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final loadedCourses = await AttendanceService.getSubjects();
      if (mounted) {
        setState(() {
          _courses = loadedCourses;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } on AttendanceException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading courses: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedCourse == null) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final loadedStudents = await AttendanceService
          .getStudentsForSubject(_selectedCourse!.courseCode);
      if (mounted) {
        setState(() {
          _students = loadedStudents;
          _filteredStudents = loadedStudents;
          _attendanceMap = {
            for (var s in loadedStudents) s.uid: false
          };
          _remarksMap = {
            for (var s in loadedStudents) s.uid: ''
          };
          _searchQuery = '';
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } on AttendanceException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Error loading students: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      _filteredStudents = query.isEmpty
          ? _students
          : _students
              .where((s) =>
                  s.displayName
                      .toLowerCase()
                      .contains(query.toLowerCase()) ||
                  (s.usn != null &&
                      s.usn!
                          .toLowerCase()
                          .contains(query.toLowerCase())))
              .toList();
    });
  }

  Future<void> _submitAttendance() async {
    if (_selectedCourse == null) {
      _showSnackbar('Please select a course.', isError: true);
      return;
    }
    if (_students.isEmpty) {
      _showSnackbar('No students loaded. Please try again.',
          isError: true);
      return;
    }
    if (_institutionId == null || _facultyUid == null) {
      _showSnackbar('Missing essential IDs for submission.',
          isError: true);
      return;
    }
    if (_selectedCourse!.departmentId == null) {
      _showSnackbar(
          'Selected course is missing a department ID.',
          isError: true);
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final dateStr =
          DateFormat('yyyy-MM-dd').format(_selectedDate);

      List<AttendanceModel> attendanceRecords =
          _students.map((student) {
        return AttendanceModel(
          courseCode: _selectedCourse!.courseCode,
          studentUid: student.uid,
          date: dateStr,
          status: _attendanceMap[student.uid] == true
              ? 'Present'
              : 'Absent',
          remarks: _remarksMap[student.uid],
          facultyUid: _facultyUid,
          institutionId: _institutionId!,
          departmentId: _selectedCourse!.departmentId!,
        );
      }).toList();

      final success = await AttendanceService.markAttendance(
        courseCode: _selectedCourse!.courseCode,
        institutionId: _institutionId!,
        departmentId: _selectedCourse!.departmentId!,
        facultyUid: _facultyUid!,
        attendanceRecords: attendanceRecords,
      );

      if (success && mounted) {
        _showSnackbar('Attendance marked successfully!',
            isError: false);
        _resetForm();
      }
    } on AttendanceException catch (e) {
      if (mounted) {
        _showSnackbar(e.message, isError: true);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(
            'Error marking attendance: ${e.toString()}',
            isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedCourse = null;
      _students = [];
      _filteredStudents = [];
      _attendanceMap = {};
      _remarksMap = {};
      _selectedDate = DateTime.now();
      _searchQuery = '';
      _isLoading = false;
      _errorMessage = null;
    });
    _loadCourses();
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: _accent,
            onPrimary: Colors.white,
            surface: _cardColor,
            onSurface: _textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: isError ? _danger : _success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return Scaffold(
          backgroundColor: _bgColor,
          drawer: isMobile ? _buildMobileDrawer() : null,
          body: isMobile
              ? Column(
                  children: [
                    _buildMobileTopBar(),
                    _buildMobileBreadcrumb(),
                    Expanded(child: _buildBody(isMobile: true)),
                  ],
                )
              : Row(
                  children: [
                    _buildSidebar(),
                    Expanded(
                      child: Column(
                        children: [
                          _buildTopBar(),
                          _buildBreadcrumb(),
                          Expanded(
                              child: _buildBody(isMobile: false)),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SIDEBAR
  // ══════════════════════════════════════════════════════════════════════════
  List<Map<String, Object?>> _menuItems() => [
        {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'active': false, 'route': null},
        {'icon': Icons.person_outline, 'label': 'Profile', 'active': false, 'route': '/faculty/profile'},
        {'icon': Icons.credit_card_outlined, 'label': 'Virtual ID', 'active': false, 'route': '/faculty/virtual-id'},
        {'icon': Icons.calendar_today_outlined, 'label': 'Timetable', 'active': false, 'route': '/faculty/timetable'},
        {'icon': Icons.group_outlined, 'label': 'Mentees', 'active': false, 'route': '/faculty/mentees'},
        {'icon': Icons.description_outlined, 'label': 'Leave', 'active': false, 'route': '/faculty/leave'},
        {'icon': Icons.attach_money, 'label': 'Payroll', 'active': false, 'route': '/faculty/payroll'},
        {'icon': Icons.celebration_outlined, 'label': 'Events', 'active': false, 'route': '/faculty/events'},
        {'icon': Icons.notifications_none_outlined, 'label': 'Meetings', 'active': false, 'route': '/faculty/meetings'},
        {'icon': Icons.assignment_outlined, 'label': 'Mark Attendance', 'active': true, 'route': '/faculty/mark-attendance'},
        {'icon': Icons.history_outlined, 'label': 'Clock-in History', 'active': false, 'route': '/faculty/attendance-history'},
        {'icon': Icons.settings_outlined, 'label': 'Settings', 'active': false, 'route': '/faculty/settings'},
      ];

  Widget _buildSidebar() {
    final items = _menuItems();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _sidebarExpanded ? 270 : 0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode
              ? [const Color(0xFF1F2937), const Color(0xFF111827)]
              : [const Color(0xFF4F46E5), const Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: _sidebarExpanded
            ? [BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.15), blurRadius: 20, offset: const Offset(4, 0))]
            : [],
      ),
      child: _sidebarExpanded
          ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                  decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1)))),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Center(
                          child: Text('A',
                              style: TextStyle(
                                  color: _isDarkMode ? const Color(0xFF1F2937) : _accent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text('Acadexa',
                            style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                      ),
                      Container(
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
                          onPressed: () => setState(() => _sidebarExpanded = false),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: items.map((item) {
                      final isActive = item['active'] == true;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final route = item['route'];
                              if (route != null && _institutionId != null) {
                                context.push('/$_institutionId${route as String}');
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: isActive ? Border.all(color: Colors.white.withOpacity(0.3)) : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(item['icon'] as IconData,
                                      color: Colors.white.withOpacity(isActive ? 1.0 : 0.7), size: 24),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(item['label'] as String,
                                        style: TextStyle(
                                            color: Colors.white.withOpacity(isActive ? 1.0 : 0.8),
                                            fontSize: 15,
                                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _footerLink('Help & Support', Icons.help_outline_rounded),
                      const SizedBox(height: 4),
                      _footerLink('Documentation', Icons.description_outlined),
                    ],
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _footerLink(String label, IconData icon) => InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.white.withOpacity(0.6)),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: _cardColor,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF4338CA)])),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('A', style: TextStyle(color: _accent, fontWeight: FontWeight.w900, fontSize: 22))),
                ),
                const SizedBox(width: 14),
                const Text('Acadexa',
                    style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _menuItems().map((item) {
                final isActive = item['active'] == true;
                return ListTile(
                  leading: Icon(item['icon'] as IconData,
                      color: isActive ? _accent : _textSecondary),
                  title: Text(item['label'] as String,
                      style: TextStyle(
                          color: isActive ? _accent : _textPrimary,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500)),
                  selected: isActive,
                  selectedTileColor: _accent.withOpacity(0.1),
                  onTap: () {
                    Navigator.pop(context);
                    final route = item['route'];
                    if (route != null && _institutionId != null) {
                      context.push('/$_institutionId${route as String}');
                    }
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TOP BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          if (!_sidebarExpanded)
            Container(
              margin: const EdgeInsets.only(right: 16),
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _sidebarExpanded = true),
                  borderRadius: BorderRadius.circular(12),
                  child: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          const Text('Mark Attendance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _accent, letterSpacing: -0.3)),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 18),
                  Icon(Icons.search_rounded, color: _textSecondary, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search students, courses...',
                        hintStyle: TextStyle(color: _textSecondary, fontSize: 15),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: TextStyle(color: _textPrimary, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: IconButton(
              icon: Icon(
                _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: _isDarkMode ? const Color(0xFFFBBF24) : _accent,
                size: 22,
              ),
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  icon: Icon(Icons.notifications_rounded, color: _textPrimary, size: 24),
                  onPressed: () {},
                ),
              ),
              Positioned(
                right: 12, top: 12,
                child: Container(width: 9, height: 9,
                    decoration: const BoxDecoration(color: _danger, shape: BoxShape.circle)),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(border: Border(left: BorderSide(color: _borderColor))),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: const Center(
                    child: Text('FC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Faculty', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary)),
                    const SizedBox(height: 2),
                    Text('Faculty Member', style: TextStyle(fontSize: 13, color: _textSecondary)),
                  ],
                ),
                const SizedBox(width: 10),
                PopupMenuButton(
                  icon: Icon(Icons.arrow_drop_down_rounded, color: _textSecondary, size: 26),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: _cardColor,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(children: [
                        Icon(Icons.settings_rounded, size: 20, color: _textPrimary),
                        const SizedBox(width: 14),
                        Text('Settings', style: TextStyle(fontSize: 15, color: _textPrimary)),
                      ]),
                      onTap: () {},
                    ),
                    PopupMenuItem(
                      child: const Row(children: [
                        Icon(Icons.logout_rounded, size: 20, color: _danger),
                        SizedBox(width: 14),
                        Text('Logout', style: TextStyle(color: _danger, fontSize: 15)),
                      ]),
                      onTap: () async {
                        final router = GoRouter.of(context);
                        await SessionManager.clearSession();
                        await AuthService.logout();
                        router.go('/login');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(10)),
              child: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                onPressed: () => Scaffold.of(context).openDrawer(),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Mark Attendance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _accent),
                overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: _isDarkMode ? const Color(0xFFFBBF24) : _accent,
            ),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          Text('Home', style: TextStyle(fontSize: 14, color: _textSecondary)),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right_rounded, size: 18, color: _textSecondary),
          const SizedBox(width: 10),
          const Text('Mark Attendance',
              style: TextStyle(fontSize: 14, color: _accent, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMobileBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          Icon(Icons.home_outlined, size: 13, color: _textSecondary),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 13, color: _textSecondary),
          const SizedBox(width: 4),
          const Text('Mark Attendance',
              style: TextStyle(fontSize: 12, color: _accent, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BODY
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBody({required bool isMobile}) {
    final pad = isMobile ? 16.0 : 28.0;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _accent));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 780),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page heading
              Text('Mark Attendance',
                  style: TextStyle(
                      fontSize: isMobile ? 22 : 26,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                      letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text('Select a course and mark student attendance for the session',
                  style: TextStyle(fontSize: isMobile ? 13 : 14, color: _textSecondary)),
              SizedBox(height: isMobile ? 20 : 28),

              // Error banner
              if (_errorMessage != null) ...[
                _buildErrorBanner(),
                const SizedBox(height: 16),
              ],

              // Course + Date card
              _buildCard(
                icon: Icons.tune_rounded,
                iconColor: _accent,
                title: 'Session Setup',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _sectionLabel('Course'),
                    const SizedBox(height: 8),
                    _buildCourseDropdown(),
                    const SizedBox(height: 16),
                    _sectionLabel('Date'),
                    const SizedBox(height: 8),
                    _buildDatePicker(),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Students section
              if (_students.isNotEmpty) ...[
                _buildCard(
                  icon: Icons.groups_rounded,
                  iconColor: _success,
                  title: 'Students',
                  trailing: _buildPresentBadge(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildSearchBar(),
                      const SizedBox(height: 12),
                      _buildQuickActions(isMobile),
                      const SizedBox(height: 16),
                      if (_filteredStudents.isEmpty)
                        _buildEmptySearchState()
                      else
                        _buildStudentsList(isMobile),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (_selectedCourse != null) ...[
                _buildNoStudentsState(),
                const SizedBox(height: 16),
              ],

              // Action buttons
              _buildActionButtons(isMobile),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Card wrapper ───────────────────────────────────────────────────────────
  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(_isDarkMode ? 0.1 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
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
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(title,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary)),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textSecondary,
            letterSpacing: 0.3),
      );

  // ── Present badge ──────────────────────────────────────────────────────────
  Widget _buildPresentBadge() {
    final presentCount =
        _attendanceMap.values.where((v) => v).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _success.withOpacity(_isDarkMode ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: _success.withOpacity(_isDarkMode ? 0.3 : 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: _success, size: 14),
          const SizedBox(width: 5),
          Text(
            '$presentCount/${_students.length} Present',
            style: TextStyle(
                fontSize: 12,
                color: _success,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ── Error banner ───────────────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _danger.withOpacity(_isDarkMode ? 0.15 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _danger.withOpacity(_isDarkMode ? 0.3 : 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: _danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_errorMessage!,
                style: TextStyle(
                    color: _danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: _danger, size: 18),
            onPressed: () => setState(() => _errorMessage = null),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // ── Course dropdown ────────────────────────────────────────────────────────
  Widget _buildCourseDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(10),
        color: _bgColor,
      ),
      child: DropdownButton<Course>(
        value: _selectedCourse,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: _cardColor,
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            color: _textSecondary),
        items: _courses
            .map((course) => DropdownMenuItem(
                  value: course,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(course.courseName,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                                fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          '${course.courseCode} • ${course.program} • Sem ${course.semester}',
                          style: TextStyle(
                              fontSize: 12, color: _textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
        hint: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Select a course',
              style: TextStyle(color: _textSecondary, fontSize: 14)),
        ),
        onChanged: (course) {
          setState(() => _selectedCourse = course);
          if (course != null) _loadStudents();
        },
      ),
    );
  }

  // ── Date picker ────────────────────────────────────────────────────────────
  Widget _buildDatePicker() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _selectDate,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: _borderColor),
            borderRadius: BorderRadius.circular(10),
            color: _bgColor,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.calendar_today_rounded,
                    color: _accent, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary),
              ),
              const Spacer(),
              Icon(Icons.keyboard_arrow_down_rounded,
                  color: _textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(10),
        color: _bgColor,
      ),
      child: TextField(
        onChanged: _filterStudents,
        style: TextStyle(fontSize: 14, color: _textPrimary),
        decoration: InputDecoration(
          hintText: 'Search by name or USN...',
          hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
          border: InputBorder.none,
          prefixIcon:
              Icon(Icons.search_rounded, color: _textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      color: _textSecondary, size: 18),
                  onPressed: () => _filterStudents(''),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 13),
        ),
      ),
    );
  }

  // ── Quick actions ──────────────────────────────────────────────────────────
  Widget _buildQuickActions(bool isMobile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _quickBtn('All Present', Icons.check_circle_rounded, _success, () {
            setState(() {
              for (var s in _filteredStudents) {
                _attendanceMap[s.uid] = true;
              }
            });
          }),
          const SizedBox(width: 8),
          _quickBtn('All Absent', Icons.cancel_rounded, _danger, () {
            setState(() {
              for (var s in _filteredStudents) {
                _attendanceMap[s.uid] = false;
              }
            });
          }),
          const SizedBox(width: 8),
          _quickBtn('Clear', Icons.refresh_rounded, _warning, () {
            setState(() {
              for (var s in _students) {
                _attendanceMap[s.uid] = false;
              }
            });
          }),
        ],
      ),
    );
  }

  Widget _quickBtn(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(_isDarkMode ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: color.withOpacity(_isDarkMode ? 0.3 : 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Student list ───────────────────────────────────────────────────────────
  Widget _buildStudentsList(bool isMobile) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        final isPresent = _attendanceMap[student.uid] ?? false;
        final remarks = _remarksMap[student.uid] ?? '';
        final borderCol = isPresent
            ? _success.withOpacity(_isDarkMode ? 0.4 : 0.3)
            : _borderColor;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: borderCol,
                  width: isPresent ? 1.5 : 1),
              boxShadow: [
                BoxShadow(
                    color: Colors.black
                        .withOpacity(_isDarkMode ? 0.08 : 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 1)),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 4),
                childrenPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    // Checkbox
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _attendanceMap[student.uid] = !isPresent;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          color: isPresent
                              ? _success
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isPresent
                                ? _success
                                : _borderColor,
                            width: 2,
                          ),
                        ),
                        child: isPresent
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Student info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.displayName,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: _textPrimary)),
                          if (student.usn != null)
                            Text(student.usn!,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _textSecondary)),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPresent
                            ? _success.withOpacity(
                                _isDarkMode ? 0.15 : 0.08)
                            : _danger.withOpacity(
                                _isDarkMode ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isPresent
                              ? _success.withOpacity(
                                  _isDarkMode ? 0.3 : 0.2)
                              : _danger.withOpacity(
                                  _isDarkMode ? 0.3 : 0.2),
                        ),
                      ),
                      child: Text(
                        isPresent ? 'Present' : 'Absent',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isPresent ? _success : _danger,
                        ),
                      ),
                    ),
                  ],
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(color: _borderColor)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Text('Remarks (Optional)',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _textSecondary)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: _borderColor),
                            borderRadius: BorderRadius.circular(8),
                            color: _bgColor,
                          ),
                          child: TextField(
                            onChanged: (value) => setState(() {
                              _remarksMap[student.uid] = value;
                            }),
                            controller: TextEditingController(
                                text: remarks),
                            maxLines: 2,
                            minLines: 1,
                            style: TextStyle(
                                fontSize: 13, color: _textPrimary),
                            decoration: InputDecoration(
                              hintText:
                                  'e.g., Late arrival, Medical leave...',
                              hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: _textSecondary),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Empty search state ─────────────────────────────────────────────────────
  Widget _buildEmptySearchState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                color: _textSecondary, size: 40),
            const SizedBox(height: 10),
            Text('No students match "$_searchQuery"',
                style: TextStyle(color: _textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── No students state ──────────────────────────────────────────────────────
  Widget _buildNoStudentsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment_outlined,
                  color: _accent.withOpacity(0.5), size: 36),
            ),
            const SizedBox(height: 12),
            Text('No students enrolled',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary)),
            const SizedBox(height: 4),
            Text('No students found for this course.',
                style: TextStyle(fontSize: 13, color: _textSecondary)),
          ],
        ),
      ),
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────────
  Widget _buildActionButtons(bool isMobile) {
    return isMobile
        ? Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _students.isEmpty ? null : _submitAttendance,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    _isLoading ? 'Submitting...' : 'Submit Attendance',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _isDarkMode
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E7EB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reset Form',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: _borderColor),
                  ),
                ),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reset Form',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: _borderColor),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed:
                      _students.isEmpty ? null : _submitAttendance,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    _isLoading ? 'Submitting...' : 'Submit Attendance',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _isDarkMode
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E7EB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          );
  }
}