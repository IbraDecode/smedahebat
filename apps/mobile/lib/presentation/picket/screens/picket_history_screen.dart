import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/auth_provider.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../providers/picket_provider.dart';

class PicketHistoryScreen extends ConsumerStatefulWidget {
  final String? classId;

  const PicketHistoryScreen({super.key, this.classId});

  @override
  ConsumerState<PicketHistoryScreen> createState() => _PicketHistoryScreenState();
}

class _PicketHistoryScreenState extends ConsumerState<PicketHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      final classId = widget.classId;
      if (classId != null) {
        ref.read(picketProvider.notifier).fetchHistory(classId: classId);
        ref.read(picketProvider.notifier).fetchStats(classId);
      } else if (auth.role == 'teacher' || auth.role == 'admin') {
        _showClassPickerForHistory();
      } else {
        ref.read(picketProvider.notifier).fetchHistory();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(picketProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Piket'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Riwayat'),
            Tab(text: 'Statistik'),
          ],
        ),
      ),
      body: state.isLoading && state.history.isEmpty && state.stats == null
          ? _buildShimmer()
          : state.error != null && state.history.isEmpty && state.stats == null
              ? ErrorState(
                  message: state.error!,
                  onRetry: () {
                    final classId = widget.classId;
                    if (auth.role == 'student') {
                      ref.read(picketProvider.notifier).fetchHistory();
                    } else if (classId != null) {
                      ref.read(picketProvider.notifier).fetchHistory(classId: classId);
                      ref.read(picketProvider.notifier).fetchStats(classId);
                    }
                  },
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHistoryTab(state, auth),
                    _buildStatsTab(state, auth),
                  ],
                ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerLoading.listItem(height: 72),
      ),
    );
  }

  Widget _buildHistoryTab(PicketState state, AuthState auth) {
    if (state.history.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: 'Belum ada riwayat piket',
        subtitle: 'Riwayat piket akan muncul setelah kamu check-in',
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        final classId = widget.classId;
        if (classId != null) {
          return ref.read(picketProvider.notifier).fetchHistory(classId: classId);
        }
        return ref.read(picketProvider.notifier).fetchHistory();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = state.history[index];
          return _buildHistoryItem(item);
        },
      ),
    );
  }

  Widget _buildHistoryItem(PicketLogItem item) {
    final isDone = item.status == 'done' || item.status == 'selesai';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDone ? AppColors.success.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.textHint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDone ? Icons.check_circle : Icons.pending_outlined,
                color: isDone ? AppColors.success : AppColors.textHint,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.day,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (item.studentName != null)
                    Text(
                      item.studentName!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isDone ? 'Selesai' : 'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDone ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
                if (item.time != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.time!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab(PicketState state, AuthState auth) {
    final stats = state.stats;

    return RefreshIndicator(
      onRefresh: () {
        final classId = widget.classId;
        if (classId != null) {
          return ref.read(picketProvider.notifier).fetchStats(classId);
        }
        return Future.value();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: stats == null
            ? const EmptyState(
                icon: Icons.bar_chart,
                title: 'Belum ada data statistik',
              )
            : Column(
                children: [
                  _buildStatsGrid(stats),
                  const SizedBox(height: 24),
                  _buildProgressChart(stats),
                  const SizedBox(height: 24),
                  _buildStatsCard(stats),
                ],
              ),
      ),
    );
  }

  Widget _buildStatsGrid(PicketStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
            icon: Icons.calendar_month_outlined,
            label: 'Total',
            value: '${stats.total}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            icon: Icons.check_circle_outline,
            label: 'Selesai',
            value: '${stats.done}',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            icon: Icons.cancel_outlined,
            label: 'Terlewat',
            value: '${stats.missed}',
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart(PicketStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text(
            'Tingkat Kehadiran Piket',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: stats.percentage / 100,
                    strokeWidth: 12,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      stats.percentage >= 80
                          ? AppColors.success
                          : stats.percentage >= 50
                              ? AppColors.warning
                              : AppColors.error,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${stats.percentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'kehadiran',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(AppColors.success, 'Hadir (${stats.done})'),
              const SizedBox(width: 16),
              _buildLegend(AppColors.error, 'Alpa (${stats.missed})'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatsCard(PicketStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Total jadwal piket', '${stats.total} kali'),
          const Divider(height: 20),
          _buildSummaryRow('Sudah dilaksanakan', '${stats.done} kali'),
          const Divider(height: 20),
          _buildSummaryRow('Terlewat', '${stats.missed} kali'),
          const Divider(height: 20),
          _buildSummaryRow(
            'Persentase kehadiran',
            '${stats.percentage.toStringAsFixed(1)}%',
            valueColor: stats.percentage >= 80
                ? AppColors.success
                : stats.percentage >= 50
                    ? AppColors.warning
                    : AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showClassPickerForHistory() {
    Future.delayed(Duration.zero, () async {
      if (!mounted) return;
      final classes = <String>['X-A', 'X-B', 'XI-A', 'XI-B', 'XII-A', 'XII-B'];
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Pilih Kelas'),
          children: classes
              .map((c) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, c),
                    child: Text(c),
                  ))
              .toList(),
        ),
      );
      if (result != null) {
        ref.read(picketProvider.notifier).fetchHistory(classId: result);
        ref.read(picketProvider.notifier).fetchStats(result);
      }
    });
  }
}
