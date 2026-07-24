import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/register_screen.dart';
import '../../presentation/auth/otp_screen.dart';
import '../../presentation/auth/set_password_screen.dart';
import '../../presentation/splash/splash_screen.dart';
import '../../presentation/shell/main_shell.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/dashboard/dashboard_screen.dart';
import '../../presentation/academic/academic_home_screen.dart';
import '../../presentation/academic/screens/schedule_screen.dart';
import '../../presentation/academic/screens/schedule_management_screen.dart';
import '../../presentation/academic/screens/schedule_form_screen.dart';
import '../../presentation/assignment/screens/assignment_list_screen.dart';
import '../../presentation/assignment/screens/assignment_detail_screen.dart';
import '../../presentation/assignment/screens/assignment_form_screen.dart';
import '../../presentation/assignment/screens/grade_submission_screen.dart';
import '../../presentation/academic/screens/subjects_screen.dart';
import '../../presentation/academic/screens/classes_screen.dart';
import '../../presentation/attendance/screens/qr_generator_screen.dart';
import '../../presentation/attendance/screens/qr_scanner_screen.dart';
import '../../presentation/attendance/screens/attendance_history_screen.dart';
import '../../presentation/attendance/screens/attendance_recap_screen.dart';
import '../../presentation/admin/screens/user_list_screen.dart';
import '../../presentation/grade/screens/grade_input_screen.dart';
import '../../presentation/grade/screens/grade_component_screen.dart';
import '../../presentation/grade/screens/component_form_screen.dart';
import '../../presentation/grade/screens/my_grades_screen.dart';
import '../../presentation/grade/screens/rapor_screen.dart';
import '../../presentation/grade/screens/rapor_generate_screen.dart';
import '../../presentation/admin/screens/user_form_screen.dart';
import '../../presentation/admin/screens/import_user_screen.dart';
import '../../presentation/admin/screens/school_profile_screen.dart';
import '../../presentation/notification/screens/announcement_list_screen.dart';
import '../../presentation/notification/screens/announcement_detail_screen.dart';
import '../../presentation/notification/screens/announcement_form_screen.dart';
import '../../presentation/notification/screens/notification_inbox_screen.dart';
import '../../presentation/picket/screens/picket_schedule_screen.dart';
import '../../presentation/picket/screens/picket_checklist_screen.dart';
import '../../presentation/picket/screens/picket_manage_screen.dart';
import '../../presentation/picket/screens/picket_history_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/otp',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/set-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SetPasswordScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/academic',
            builder: (context, state) => const AcademicHomeScreen(),
          ),
          GoRoute(
            path: '/activity',
            builder: (context, state) => const ActivityShell(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationInboxScreen(),
          ),
          GoRoute(
            path: '/announcements',
            builder: (context, state) => const AnnouncementListScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/academic/schedule',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ScheduleScreen(),
      ),
      GoRoute(
        path: '/academic/schedule/manage',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ScheduleManagementScreen(),
      ),
      GoRoute(
        path: '/academic/schedule/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ScheduleFormScreen(extra: extra);
        },
      ),
      GoRoute(
        path: '/academic/schedule/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ScheduleFormScreen(scheduleId: id, extra: extra);
        },
      ),
      GoRoute(
        path: '/academic/subjects',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SubjectsScreen(),
      ),
      GoRoute(
        path: '/academic/classes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ClassesScreen(),
      ),
      GoRoute(
        path: '/attendance/generate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QrGeneratorScreen(),
      ),
      GoRoute(
        path: '/attendance/scan',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/attendance/history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AttendanceHistoryScreen(),
      ),
      GoRoute(
        path: '/attendance/recap',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AttendanceRecapScreen(),
      ),
      GoRoute(
        path: '/attendance/recap/:classId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final classId = state.pathParameters['classId']!;
          return AttendanceRecapScreen(classId: classId);
        },
      ),
      GoRoute(
        path: '/attendance/history/:classId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final classId = state.pathParameters['classId']!;
          return AttendanceHistoryScreen(classId: classId);
        },
      ),
      GoRoute(
        path: '/admin/users',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UserListScreen(),
      ),
      GoRoute(
        path: '/admin/users/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UserFormScreen(),
      ),
      GoRoute(
        path: '/admin/users/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final user = state.extra as Map<String, dynamic>?;
          return UserFormScreen(userId: id, userData: user);
        },
      ),
      GoRoute(
        path: '/admin/users/import',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ImportUserScreen(),
      ),
      GoRoute(
        path: '/admin/school',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SchoolProfileScreen(),
      ),
      GoRoute(
        path: '/announcements/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AnnouncementFormScreen(),
      ),
      GoRoute(
        path: '/announcements/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AnnouncementDetailScreen(id: id);
        },
      ),
      GoRoute(
        path: '/assignments',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AssignmentListScreen(),
      ),
      GoRoute(
        path: '/assignments/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AssignmentFormScreen(),
      ),
      GoRoute(
        path: '/assignments/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AssignmentDetailScreen(id: id);
        },
      ),
      GoRoute(
        path: '/assignments/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          return AssignmentFormScreen(assignmentId: id, extra: extra);
        },
      ),
      GoRoute(
        path: '/assignments/:id/grade/:submissionId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final submissionId = state.pathParameters['submissionId']!;
          return GradeSubmissionScreen(assignmentId: id, submissionId: submissionId);
        },
      ),
      GoRoute(
        path: '/grade/input',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GradeInputScreen(),
      ),
      GoRoute(
        path: '/grade/components',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GradeComponentScreen(),
      ),
      GoRoute(
        path: '/grade/components/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ComponentFormScreen(extra: extra);
        },
      ),
      GoRoute(
        path: '/grade/components/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ComponentFormScreen(componentId: id, extra: extra);
        },
      ),
      GoRoute(
        path: '/grade/my',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyGradesScreen(),
      ),
      GoRoute(
        path: '/grade/rapor',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RaporScreen(),
      ),
      GoRoute(
        path: '/grade/rapor/generate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RaporGenerateScreen(),
      ),
      GoRoute(
        path: '/grade/rapor/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RaporScreen(raporId: id);
        },
      ),
      GoRoute(
        path: '/picket',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PicketScheduleScreen(),
      ),
      GoRoute(
        path: '/picket/checklist',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PicketChecklistScreen(),
      ),
      GoRoute(
        path: '/picket/checklist/:classId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final classId = state.pathParameters['classId']!;
          return PicketChecklistScreen(classId: classId);
        },
      ),
      GoRoute(
        path: '/picket/manage',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PicketManageScreen(),
      ),
      GoRoute(
        path: '/picket/history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PicketHistoryScreen(),
      ),
      GoRoute(
        path: '/picket/history/:classId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final classId = state.pathParameters['classId']!;
          return PicketHistoryScreen(classId: classId);
        },
      ),
    ],
  );
});

class ActivityShell extends StatelessWidget {
  const ActivityShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Activity'));
  }
}


