import 'package:flutter/material.dart';
import 'package:flutter_application/screens/student/student_fees_screen.dart';
import 'package:flutter_application/screens/student/student_fee_detail_screen.dart';
import 'package:flutter_application/models/student_fee_model.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/models/announcement_model.dart';
import 'package:flutter_application/screens/admin_attendance_dashboard.dart';
import 'package:flutter_application/screens/student_eligibility_screen.dart';
import 'package:flutter_application/screens/student_shell.dart';
import 'package:flutter_application/screens/user_list_screen.dart';
import 'package:flutter_application/services/api_service.dart';
// import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/auth_wrapper.dart';
import '../screens/faculty_dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/student_dashboard_screen.dart';
import '../screens/student/profile_screen.dart';
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
import '../screens/regularisation_request_screen.dart';
import '../screens/regularisation_status_screen.dart';
import '../screens/admin_regularisation_screen.dart';
import '../screens/approval_screen.dart';
import '../screens/create_exam_screen.dart';
import '../screens/exam_management_screen.dart';
import '../screens/announcements_list_screen.dart';
import '../screens/announcement_detail_screen.dart';
import '../screens/create_edit_announcement_screen.dart';
import '../screens/manage_announcements_screen.dart';
import '../screens/faculty/virtual_id_screen.dart' as faculty_vid;
import '../screens/faculty/profile_screen.dart' as faculty_profile;
import '../screens/faculty/faculty_leave_approval_screen.dart';
import '../screens/room_management_screen.dart';
import '../screens/room_editor_screen.dart';
import '../screens/exam_timetable_viewer_screen.dart';
import '../screens/faculty_timetable_screen.dart';
import '../screens/hall_allocation_screen.dart';
import '../screens/invigilator_assignment_screen.dart';
import '../screens/exam_hall_tickets_screen.dart';
import '../screens/hall_ticket_viewer_screen.dart';
import '../screens/student/student_leave_screen.dart';
import '../screens/student/leave_history_screen.dart';
import '../models/fee_structure_model.dart'; // Import FeeStructure model

final apiService = ApiService();

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
        GoRoute(
          path: '/:institutionId/student/fees',
          builder: (context, state) => const StudentFeesScreen(),
        ),
        GoRoute(
          path: '/:institutionId/student/fees/:feeId',
          builder: (context, state) {
            final fee = state.extra as StudentFee;
            return StudentFeeDetailScreen(fee: fee);
          },
        ),
         GoRoute(
          path: '/:institutionId/student/leave',
          builder: (context, state) => const StudentLeaveScreen(),
        ),
        GoRoute(
          path: '/:institutionId/student/leave/history',
          builder: (context, state) => const LeaveHistoryScreen(),
        ),
      ],
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
      builder: (context, state) {
        final structure = state.extra as FeeStructure?;
        return FeeStructureEditorScreen(feeStructure: structure);
      },
    ),
    GoRoute(
      path: '/:institutionId/admin/exam-dashboard',
      builder: (context, state) => const ExamDashboardScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/exam-management',
      builder: (context, state) => const ExamManagementScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/room-management',
      builder: (context, state) => const RoomManagementScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/room-editor',
      builder: (context, state) => const RoomEditorScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/room-editor/:roomId',
      builder: (context, state) {
        final roomId = state.pathParameters['roomId'];
        return RoomEditorScreen(roomId: roomId);
      },
    ),
    GoRoute(
      path: '/:institutionId/admin/exam-schedule-editor/:examId',
      builder: (context, state) {
        final examId = state.pathParameters['examId']; // This will be null if not present
        return ExamScheduleEditorScreen(examId: examId);
      },
    ),
    GoRoute(
      path: '/:institutionId/admin/create-exam',
      builder: (context, state) => const CreateExamScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/exams/:examId/eligibility',
      builder: (context, state) {
        final examId = state.pathParameters['examId']!;
        return StudentEligibilityScreen(examId: examId);
      },
    ),
    GoRoute(
      path: '/:institutionId/admin/exams/:examId/schedule-management',
      builder: (context, state) {
        final examId = state.pathParameters['examId']!;
        return ExamScheduleEditorScreen(examId: examId);
      },
    ),
    GoRoute(
      path: '/:institutionId/admin/exams/:examId/timetable',
      builder: (context, state) {
        final examId = state.pathParameters['examId']!;
        return ExamTimetableViewerScreen(examId: examId);
      },
    ),
    GoRoute(
      path: '/:institutionId/admin/exams/:examId/hall-allocation',
      builder: (context, state) {
        final examId = state.pathParameters['examId']!;
        return HallAllocationScreen(examId: examId);
      },
    ),
    GoRoute(
      path: '/:institutionId/admin/exams/:examId/invigilator-assignment',
      builder: (context, state) {
        final examId = state.pathParameters['examId']!;
        return InvigilatorAssignmentScreen(examId: examId);
      },
    ),
    GoRoute(
      path: '/:institutionId/admin/exams/:examId/hall-tickets',
      builder: (context, state) {
        final examId = state.pathParameters['examId']!;
        return ExamHallTicketsScreen(examId: examId);
      },
    ),
    GoRoute(
      path: '/:institutionId/admin/exams/:examId/hall-tickets/:studentId',
      builder: (context, state) {
        final examId = state.pathParameters['examId']!;
        final studentId = state.pathParameters['studentId']!;
        return HallTicketViewerScreen(examId: examId, studentId: studentId);
      },
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
      path: '/:institutionId/admin/regularisation',
      builder: (context, state) => const AdminRegularisationScreen(),
    ),
    GoRoute(
      path: '/:institutionId/admin/approval',
      builder: (context, state) => const ApprovalScreen(),
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
      path: '/:institutionId/faculty/virtual-id',
      builder: (context, state) => const faculty_vid.VirtualIdScreen(),
    ),
    GoRoute(
      path: '/:institutionId/faculty/profile',
      builder: (context, state) => const faculty_profile.ProfileScreen(),
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
      path: '/:institutionId/faculty/regularisation',
      builder: (context, state) => const RegularisationRequestScreen(),
    ),
    GoRoute(
      path: '/:institutionId/faculty/regularisation/status',
      builder: (context, state) => const RegularisationStatusScreen(),
    ),
    GoRoute(
      path: '/:institutionId/faculty/leave-approval',
      builder: (context, state) => const FacultyLeaveApprovalScreen(),
    ),
    GoRoute(
      path: '/:institutionId/faculty/timetable',
      builder: (context, state) => const FacultyTimetableScreen(),
    ),
    GoRoute(
      path: '/:institutionId/faculty/timetable/:examId',
      builder: (context, state) {
        final examId = state.pathParameters['examId']!;
        return ExamTimetableViewerScreen(examId: examId);
      },
    ),
    GoRoute(
      path: '/:institutionId/announcements',
      builder: (context, state) => const AnnouncementsListScreen(),
    ),
    GoRoute(
      path: '/:institutionId/announcements/create',
      builder: (context, state) => const CreateEditAnnouncementScreen(),
    ),
    GoRoute(
      path: '/:institutionId/announcements/manage',
      builder: (context, state) => const ManageAnnouncementsScreen(),
    ),
    GoRoute(
      path: '/:institutionId/announcements/:announcementId',
      builder: (context, state) {
        final announcement = state.extra as AnnouncementModel?;
        if (announcement != null) {
          return AnnouncementDetailScreen(announcement: announcement);
        }
        return const AnnouncementsListScreen();
      },
    ),
    GoRoute(
      path: '/:institutionId/announcements/:announcementId/edit',
      builder: (context, state) {
        final announcement = state.extra as AnnouncementModel?;
        return CreateEditAnnouncementScreen(announcement: announcement);
      },
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthWrapper(),
    ),
  ],
  refreshListenable: GoRouterRefreshStream(fb_auth.FirebaseAuth.instance.authStateChanges()),
  redirect: (BuildContext context, GoRouterState state) async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    final isLoggingIn = state.matchedLocation == '/login';

    if (user == null) {
      return isLoggingIn ? null : '/login';
    }

    if (isLoggingIn) {
      return '/';
    }

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
