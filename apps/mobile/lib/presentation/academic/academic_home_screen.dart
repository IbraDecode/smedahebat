import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../auth/auth_provider.dart';

class _AcademicMenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  final String? requiredRole;

  const _AcademicMenuItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
    this.requiredRole,
  });
}

const _menuItems = [
  _AcademicMenuItem(
    label: 'Jadwal',
    icon: Icons.calendar_month_outlined,
    color: AppColors.primary,
    route: '/academic/schedule',
  ),
  _AcademicMenuItem(
    label: 'Mapel',
    icon: Icons.book_outlined,
    color: AppColors.success,
    route: '/academic/subjects',
  ),
  _AcademicMenuItem(
    label: 'Kelola Jadwal',
    icon: Icons.edit_calendar_outlined,
    color: AppColors.accent,
    route: '/academic/schedule/manage',
    requiredRole: 'admin',
  ),
  _AcademicMenuItem(
    label: 'Kelas',
    icon: Icons.meeting_room_outlined,
    color: AppColors.secondary,
    route: '/academic/classes',
    requiredRole: 'admin',
  ),
  _AcademicMenuItem(
    label: 'Nilai',
    icon: Icons.grading_outlined,
    color: AppColors.warning,
    route: '/academic/grades',
  ),
  _AcademicMenuItem(
    label: 'Rapor',
    icon: Icons.description_outlined,
    color: AppColors.info,
    route: '/academic/report',
  ),
];

class AcademicHomeScreen extends ConsumerWidget {
  const AcademicHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final role = auth.role;

    return Scaffold(
      appBar: AppBar(title: const Text('Akademik')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Menu Akademik',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  if (item.requiredRole != null && item.requiredRole != role) {
                    return const SizedBox.shrink();
                  }
                  return _buildMenuItem(context, item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, _AcademicMenuItem item) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push(item.route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
