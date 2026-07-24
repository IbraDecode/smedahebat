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
import '../../presentation/academic/screens/subjects_screen.dart';
import '../../presentation/academic/screens/classes_screen.dart';
import '../../presentation/admin/screens/user_list_screen.dart';
import '../../presentation/admin/screens/user_form_screen.dart';
import '../../presentation/admin/screens/import_user_screen.dart';
import '../../presentation/admin/screens/school_profile_screen.dart';

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
            builder: (context, state) => const NotificationsShell(),
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
        path: '/attendance',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AttendanceScreen(),
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

class NotificationsShell extends StatelessWidget {
  const NotificationsShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Notifications'));
  }
}

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absensi')),
      body: const Center(child: Text('Attendance Screen')),
    );
  }
}
