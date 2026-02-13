import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/screens/admin_attendance_dashboard.dart';
import 'package:flutter_application/screens/user_list_screen.dart';
import 'package:go_router/go_router.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/auth_wrapper.dart';
import '../screens/faculty_dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/student_dashboard_screen.dart';
import '../screens/student/profile_screen.dart';
import '../screens/student/edit_profile_screen.dart';
import '../screens/student/virtual_id_screen.dart';
import '../screens/mark_attendance_screen.dart';
import '../screens/attendance_history_screen.dart';
import '../screens/user_details_screen.dart';
import '../screens/edit_user_details_screen.dart';
import '../screens/institution_settings_screen.dart';
import '../screens/department_details_screen.dart';
import '../screens/department_management_screen.dart';
import '../screens/class_management_screen.dart';
import '../screens/bulk_user_import_screen.dart';
import '../screens/fee_management_dashboard_screen.dart';
import '../screens/fee_structure_editor_screen.dart';
import '../screens/exam_dashboard_screen.dart';
import '../screens/exam_schedule_editor_screen.dart';
import '../screens/report_card_dashboard_screen.dart';
import '../screens/report_card_viewer_screen.dart';
import '../screens/inventory_dashboard_screen.dart';
import '../screens/inventory_item_editor_screen.dart';
import '../screens/form_builder_dashboard_screen.dart';
import '../screens/form_editor_screen.dart';
import '../screens/form_responses_screen.dart';
import '../screens/alumni_dashboard_screen.dart';
import '../screens/alumni_directory_screen.dart';
import '../screens/alumni_job_board_screen.dart';
import '../screens/student_attendance_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return StudentShell(state: state, child: child);
      },
      routes: [
        GoRoute(
          path: '/:institutionId/student/dashboard',
          builder: (context, state) => const StudentDashboardScreen(),
        ),
        GoRoute(
          path: '/:institutionId/student/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/:institutionId/student/virtual-id',
          builder: (context, state) => const VirtualIdScreen(),
        ),
        GoRoute(
          path: '/:institutionId/student/attendance',
          builder: (context, state) => const StudentAttendanceScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/:institutionId/student/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
     GoRoute(
      path: '/:institutionId/admin/attendance-dashboard',
      builder: (context, state) => const AdminAttendanceDashboardScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/class-management',
      builder: (context, state) => const ClassManagementScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/bulk-user-import',
      builder: (context, state) => const BulkUserImportScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/fee-management',
      builder: (context, state) => const FeeManagementDashboardScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/fee-structure-editor',
      builder: (context, state) => const FeeStructureEditorScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/exam-dashboard',
      builder: (context, state) => const ExamDashboardScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/exam-schedule-editor',
      builder: (context, state) => const ExamScheduleEditorScreen(),
    ),
     GoRoute(
      path: '/:institutionId/admin/report-card-dashboard',
      builder: (context, state) => const ReportCardDashboardScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/report-card-viewer',
      builder: (context, state) => const ReportCardViewerScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/inventory',
      builder: (context, state) => const InventoryDashboardScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/inventory-item-editor',
      builder: (context, state) => const InventoryItemEditorScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/form-builder',
      builder: (context, state) => const FormBuilderDashboardScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/form-editor',
      builder: (context, state) => const FormEditorScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/form-responses',
      builder: (context, state) => const FormResponsesScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/alumni-dashboard',
      builder: (context, state) => const AlumniDashboardScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/alumni-directory',
      builder: (context, state) => const AlumniDirectoryScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/alumni-job-board',
      builder: (context, state) => const AlumniJobBoardScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/institution-settings',
      builder: (context, state) => const InstitutionSettingsScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/institution-settings/:departmentName',
      builder: (context, state) {
        final departmentName = state.pathParameters['departmentName']!;
        return DepartmentDetailsScreen(departmentName: departmentName);
      },
    ),
    GoRoute(
      path: '/:institutionId/admin/institution-settings/:departmentName/:assetType',
      builder: (context, state) {
        final departmentName = state.pathParameters['departmentName']!;
        final assetType = state.pathParameters['assetType']!;
        return DepartmentManagementScreen(
          departmentName: departmentName,
          assetType: assetType,
        );
      },
    ),
    GoRoute(
      path: '/:institutionId/admin/users/:role',
      builder: (context, state) {
        final role = state.pathParameters['role']!;
        return UserListScreen(role: role);
      },
    ),
    GoRoute(
      path: '/:institutionId/admin/users/details/:uid',
      builder: (context, state) {
        final uid = state.pathParameters['uid']!;
        return UserDetailsScreen(uid: uid);
      },
    ),
    GoRoute(
      path: '/:institutionId/admin/users/edit/:uid',
      builder: (context, state) {
        final user = state.extra as UserModel;
        return EditUserDetailsScreen(user: user);
      },
    ),
    GoRoute(
      path: '/:institutionId/faculty/dashboard',
      builder: (context, state) => const FacultyDashboardScreen(),
    ),
    GoRoute(
      path: '/:institutionId/faculty/mark-attendance',
      builder: (context, state) => const MarkAttendanceScreen(),
    ),
    GoRoute(
      path: '/:institutionId/faculty/attendance-history',
      builder: (context, state) => const AttendanceHistoryScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthWrapper(),
    ),
  ],
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (BuildContext context, GoRouterState state) async {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggingIn = state.matchedLocation == '/login';

    // 1. User is not logged in
    if (user == null) {
      // If they are not on the login page, send them there.
      return isLoggingIn ? null : '/login';
    }

    // 2. User IS logged in and is trying to access the login page
    if (isLoggingIn) {
      // Redirect a logged-in user away from the login page.
      // Sending them to the root is a safe choice, as it will be
      // handled by a nested route or another redirect if necessary.
      return '/';
    }

    // 3. User is logged in and not on the login page. Allow navigation.
    return null;
  },
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class StudentShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const StudentShell({super.key, required this.child, required this.state});

  @override
  Widget build(BuildContext context) {
    final location = state.uri.toString();
    final institutionId = state.pathParameters['institutionId'];
    final bool isDashboard = location == '/$institutionId/student/dashboard';

    if (isDashboard) {
      return child;
    }

    String title = 'Student';
    if (location == '/$institutionId/student/profile') {
      title = 'Profile';
    } else if (location == '/$institutionId/student/virtual-id') {
      title = 'Virtual ID';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            context.go('/$institutionId/student/dashboard');
          },
        ),
      ),
      body: child,
    );
  }
}