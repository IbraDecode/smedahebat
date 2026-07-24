import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../academic/providers/teacher_subject_provider.dart';
import '../../auth/auth_provider.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../providers/attendance_provider.dart';

class AttendanceRecapScreen extends ConsumerStatefulWidget {
  final String? classId;

  const AttendanceRecapScreen({super.key, this.classId});

  @override
  ConsumerState<AttendanceRecapScreen> createState() =>
      _AttendanceRecapScreenState();
}

class _AttendanceRecapScreenState extends ConsumerState<AttendanceRecapScreen> {
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final role = ref.read(authProvider).role;
      if (role != 'student') {
        ref.read(teacherSubjectProvider.notifier).fetchClasses();
      }
      if (widget.classId != null) {
        _selectedClassId = widget.classId;
        ref.read(attendanceProvider.notifier).fetchRecap(widget.classId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceProvider);
    final auth = ref.watch(authProvider);
    final tsState = ref.watch(teacherSubjectProvider);
    final notifier = ref.read(attendanceProvider.notifier);
    final isStudent = auth.role == 'student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Absensi'),
      ),
      body: Column(
        children: [
          if (!isStudent)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: DropdownButtonFormField<String>(
                value: _selectedClassId,
                decoration: InputDecoration(
                  labelText: 'Pilih Kelas',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: tsState.classes.map((c) {
                  final id = c['id']?.toString() ?? '';
                  return DropdownMenuItem(
                    value: id,
                    child: Text(c['name'] as String? ?? ''),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() => _selectedClassId = v);
                  if (v != null) notifier.fetchRecap(v);
                },
              ),
            ),
          Expanded(
            child: state.isLoading
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: ShimmerLoading.statGrid(),
                  )
                : state.error != null
                    ? ErrorState(
                        message: state.error!,
                        onRetry: () {
                          if (!isStudent && _selectedClassId != null) {
                            notifier.fetchRecap(_selectedClassId!);
                          }
                        },
                      )
                : state.recap != null
                    ? _buildRecapContent(context, state.recap!)
                    : ListView(
                        children: const [
                          SizedBox(height: 80),
                          EmptyState(
                            icon: Icons.pie_chart_outline,
                            title: 'Belum ada data rekap',
                            subtitle: 'Rekap absensi akan muncul setelah ada sesi absensi',
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapContent(BuildContext context, AttendanceRecap recap) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDonutChart(recap),
          const SizedBox(height: 24),
          _buildStatCard(
            'Total',
            '${recap.total}',
            AppColors.primary,
            Icons.people_outline,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Hadir',
                  '${recap.hadir}',
                  AppColors.success,
                  Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Sakit',
                  '${recap.sakit}',
                  AppColors.warning,
                  Icons.medical_services_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Izin',
                  '${recap.izin}',
                  AppColors.info,
                  Icons.description_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Alpa',
                  '${recap.alpa}',
                  AppColors.error,
                  Icons.cancel_outlined,
                ),
              ),
            ],
          ),
          if (recap.terlambat > 0) ...[
            const SizedBox(height: 8),
            _buildStatCard(
              'Terlambat',
              '${recap.terlambat}',
              AppColors.secondary,
              Icons.access_time,
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur ekspor akan tersedia')),
              );
            },
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Export (.xlsx)'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDonutChart(AttendanceRecap recap) {
    final total = recap.total > 0 ? recap.total : 1;
    final data = <_ChartSegment>[
      _ChartSegment('Hadir', recap.hadir, AppColors.success),
      _ChartSegment('Sakit', recap.sakit, AppColors.warning),
      _ChartSegment('Izin', recap.izin, AppColors.info),
      _ChartSegment('Alpa', recap.alpa, AppColors.error),
      if (recap.terlambat > 0)
        _ChartSegment('Terlambat', recap.terlambat, AppColors.secondary),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                size: const Size(180, 180),
                painter: _DonutPainter(data, total),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(recap.hadirPercent * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Kehadiran',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: data.map((d) {
                final percent = total > 0 ? (d.value / total * 100).round() : 0;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: d.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${d.label} $percent%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartSegment {
  final String label;
  final int value;
  final Color color;

  const _ChartSegment(this.label, this.value, this.color);
}

class _DonutPainter extends CustomPainter {
  final List<_ChartSegment> data;
  final int total;

  _DonutPainter(this.data, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.round;

    double startAngle = -1.5708;
    for (final segment in data) {
      if (segment.value == 0) continue;
      final sweepAngle = (segment.value / total) * 6.2832;
      paint.color = segment.color;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    paint.color = AppColors.border.withValues(alpha: 0.3);
    final remaining = total - data.fold(0, (sum, d) => sum + d.value);
    if (remaining > 0) {
      final sweepAngle = (remaining / total) * 6.2832;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
