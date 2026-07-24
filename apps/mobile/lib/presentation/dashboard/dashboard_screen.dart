import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../auth/auth_provider.dart';
import '../common/widgets/error_state.dart';
import '../common/widgets/shimmer_loading.dart';
import 'dashboard_provider.dart';
import 'widgets/announcement_card.dart';
import 'widgets/schedule_card.dart';
import 'widgets/stat_card.dart';
import 'widgets/task_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final dashboard = ref.watch(dashboardProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).fetchDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: dashboard.isLoading && dashboard.data == null
            ? _buildShimmerLoading()
            : dashboard.error != null && dashboard.data == null
                ? SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: ErrorState(
                      message: dashboard.error!,
                      onRetry: () =>
                          ref.read(dashboardProvider.notifier).fetchDashboard(),
                    ),
                  )
                : _buildContent(context, ref, auth, dashboard),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            ShimmerBox(width: 200, height: 20),
            const Spacer(),
            ShimmerBox(width: 48, height: 48, borderRadius: 24),
          ],
        ),
        const SizedBox(height: 24),
        ShimmerLoading.card(height: 160),
        const SizedBox(height: 24),
        ShimmerBox(width: 120, height: 20),
        const SizedBox(height: 12),
        ShimmerLoading.statGrid(),
        const SizedBox(height: 24),
        ShimmerBox(width: 180, height: 20),
        const SizedBox(height: 12),
        ShimmerLoading.announcement(),
        const SizedBox(height: 8),
        ShimmerLoading.announcement(),
        const SizedBox(height: 24),
        ShimmerBox(width: 150, height: 20),
        const SizedBox(height: 12),
        ShimmerLoading.taskItem(),
        const SizedBox(height: 8),
        ShimmerLoading.taskItem(),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AuthState auth,
    DashboardState dashboard,
  ) {
    final data = dashboard.data;
    final isStudentOrTeacher = auth.role == 'student' || auth.role == 'teacher';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildHeader(context, auth),
        const SizedBox(height: 24),
        if (data?.todaySchedule != null && isStudentOrTeacher)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: ScheduleCard(
              subject: data!.todaySchedule!.subject,
              teacher: data.todaySchedule!.teacher,
              room: data.todaySchedule!.room,
              startTime: data.todaySchedule!.startTime,
              endTime: data.todaySchedule!.endTime,
              nextSubject: data.todaySchedule!.nextSubject,
            ),
          ),
        _buildQuickStats(context, data?.stats, auth.role),
        const SizedBox(height: 24),
        _buildAttendanceCard(context, auth.role),
        if (data?.recentAnnouncements != null &&
            data!.recentAnnouncements.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Pengumuman Terbaru', onSeeAll: () => context.push('/announcements')),
          const SizedBox(height: 12),
          ...data.recentAnnouncements.take(3).map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AnnouncementCard(
                    id: a.id,
                    title: a.title,
                    body: a.body,
                    date: a.date,
                    isRead: a.isRead,
                    onTap: () {
                      ref
                          .read(dashboardProvider.notifier)
                          .markAnnouncementRead(a.id);
                    },
                  ),
                ),
              ),
        ],
        if (data?.upcomingTasks != null &&
            data!.upcomingTasks.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Tugas Mendatang', onSeeAll: () => context.push('/assignments')),
          const SizedBox(height: 12),
          ...data.upcomingTasks.take(3).map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TaskCard(
                    id: t.id,
                    name: t.name,
                    subject: t.subject,
                    deadline: t.deadline,
                    status: t.status,
                    onTap: () => context.push('/assignments/${t.id}'),
                  ),
                ),
              ),
        ],
        if (data?.tomorrowSchedule != null) ...[
          const SizedBox(height: 24),
          _buildTomorrowPreview(context, data!.tomorrowSchedule!),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AuthState auth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, ${auth.name ?? 'Pengguna'} \u{1F44B}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Semangat belajar hari ini!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.person, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    Map<String, dynamic>? stats,
    String? role,
  ) {
    if (stats == null || stats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistik',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final entries = stats.entries.toList();
            final rows = <Widget>[];
            for (var i = 0; i < entries.length; i += 2) {
              final row = Row(
                children: [
                  if (i < entries.length)
                    _buildStatItem(context, entries[i]),
                  if (i + 1 < entries.length) ...[
                    const SizedBox(width: 12),
                    _buildStatItem(context, entries[i + 1]),
                  ],
                ],
              );
              rows.add(row);
              if (i + 2 < entries.length) {
                rows.add(const SizedBox(height: 12));
              }
            }
            return Column(children: rows);
          },
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(BuildContext context, String? role) {
    if (role == 'admin') return const SizedBox.shrink();

    final isTeacher = role == 'teacher';
    final primaryLabel = isTeacher ? 'Generate QR Absensi' : 'Scan QR Absensi';
    final primaryIcon = isTeacher ? Icons.qr_code_2 : Icons.qr_code_scanner;
    final primaryRoute = isTeacher ? '/attendance/generate' : '/attendance/scan';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Absensi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isTeacher
                          ? 'Buat sesi absensi untuk kelas'
                          : 'Scan QR untuk presensi',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAttendanceAction(
                  icon: primaryIcon,
                  label: primaryLabel,
                  onTap: () => context.push(primaryRoute),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAttendanceAction(
                  icon: Icons.history,
                  label: 'Riwayat',
                  onTap: () => context.push('/attendance/history'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, MapEntry<String, dynamic> entry) {
    final iconMap = <String, IconData>{
      'kehadiran': Icons.check_circle_outline,
      'tugas': Icons.assignment_outlined,
      'mapel': Icons.book_outlined,
      'prestasi': Icons.star_outline,
      'kelas': Icons.meeting_room_outlined,
      'siswa': Icons.people_outline,
      'guru': Icons.school_outlined,
      'total_siswa': Icons.people_outline,
      'total_guru': Icons.school_outlined,
      'total_kelas': Icons.meeting_room_outlined,
      'total_mapel': Icons.book_outlined,
    };
    final colorMap = <String, Color>{
      'kehadiran': AppColors.success,
      'tugas': AppColors.warning,
      'mapel': AppColors.info,
      'prestasi': AppColors.secondary,
      'kelas': AppColors.accent,
      'siswa': AppColors.primary,
      'guru': AppColors.success,
      'total_siswa': AppColors.primary,
      'total_guru': AppColors.success,
      'total_kelas': AppColors.accent,
      'total_mapel': AppColors.info,
    };

    final icon = iconMap[entry.key] ?? Icons.bar_chart;
    final color = colorMap[entry.key] ?? AppColors.primary;
    final label = _statLabel(entry.key);
    final value = entry.value?.toString() ?? '-';

    return StatCard(label: label, value: value, icon: icon, color: color);
  }

  String _statLabel(String key) {
    switch (key) {
      case 'kehadiran':
        return 'Kehadiran';
      case 'tugas':
        return 'Tugas';
      case 'mapel':
        return 'Mata Pelajaran';
      case 'prestasi':
        return 'Prestasi';
      case 'kelas':
        return 'Kelas';
      case 'siswa':
        return 'Siswa';
      case 'guru':
        return 'Guru';
      case 'total_siswa':
        return 'Total Siswa';
      case 'total_guru':
        return 'Total Guru';
      case 'total_kelas':
        return 'Total Kelas';
      case 'total_mapel':
        return 'Total Mapel';
      default:
        return key;
    }
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('Lihat Semua'),
          ),
      ],
    );
  }

  Widget _buildTomorrowPreview(
    BuildContext context,
    Map<String, dynamic> tomorrow,
  ) {
    final subjects = tomorrow['subjects'] as List<dynamic>? ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Besok, ${tomorrow['date'] ?? '-'}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          if (subjects.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Tidak ada jadwal',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
            )
          else
            ...subjects.take(3).map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${s['subject'] ?? ''} - ${s['time'] ?? ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
