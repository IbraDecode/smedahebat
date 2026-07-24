import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../academic/providers/teacher_subject_provider.dart';
import '../../common/widgets/app_button.dart';
import '../providers/attendance_provider.dart';
import '../widgets/qr_display.dart';

class QrGeneratorScreen extends ConsumerStatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  ConsumerState<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends ConsumerState<QrGeneratorScreen> {
  String? _selectedScheduleId;
  String? _selectedClassId;
  String? _selectedSubjectId;
  Timer? _scannedTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(teacherSubjectProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _scannedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceProvider);
    final tsState = ref.watch(teacherSubjectProvider);
    final notifier = ref.read(attendanceProvider.notifier);

    if (state.activeToken != null) {
      return _buildQrDisplay(context, state, notifier);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate QR Absensi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buat Sesi Absensi Baru',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih kelas dan mapel untuk generate QR',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            _buildDropdown(
              context,
              label: 'Kelas',
              value: _selectedClassId,
              items: tsState.classes,
              labelKey: 'name',
              valueKey: 'id',
              onChanged: (v) {
                setState(() => _selectedClassId = v);
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              context,
              label: 'Mata Pelajaran (opsional)',
              value: _selectedSubjectId,
              items: tsState.subjects,
              labelKey: 'name',
              valueKey: 'id',
              onChanged: (v) {
                setState(() => _selectedSubjectId = v);
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              context,
              label: 'Jadwal (opsional)',
              value: _selectedScheduleId,
              items: tsState.assignments,
              labelBuilder: (m) {
                final subject = m['subjectName'] as String? ?? m['subject'] as String? ?? '';
                final cls = m['className'] as String? ?? m['class'] as String? ?? '';
                final time = m['startTime'] as String? ?? '';
                return '$subject - $cls${time.isNotEmpty ? ' ($time)' : ''}';
              },
              valueKey: 'id',
              onChanged: (v) {
                setState(() => _selectedScheduleId = v);
              },
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Generate QR',
              isLoading: state.isLoading,
              icon: Icons.qr_code_2,
              onPressed: _selectedClassId != null
                  ? () async {
                      await notifier.generateQr(
                        scheduleId: _selectedScheduleId ?? '',
                        classId: _selectedClassId,
                        subjectId: _selectedSubjectId,
                      );
                    }
                  : null,
            ),
            if (state.error != null) ...[
              const SizedBox(height: 16),
              Text(
                state.error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQrDisplay(
    BuildContext context,
    AttendanceState state,
    AttendanceNotifier notifier,
  ) {
    _startScannedPolling(notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('QR Absensi'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _scannedTimer?.cancel();
            notifier.resetSession();
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SMEDA HEBAT',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ABSENSI',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 32),
                QrDisplay(
                  token: state.activeToken!,
                  expiresInSeconds: state.expiresInSeconds ?? 30,
                  onExpired: () {
                    _scannedTimer?.cancel();
                    notifier.resetSession();
                  },
                  onStop: () async {
                    if (state.sessionId != null) {
                      _scannedTimer?.cancel();
                      await notifier.deactivateSession(state.sessionId!);
                      notifier.resetSession();
                    }
                  },
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${state.scannedCount} Siswa sudah scan',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startScannedPolling(AttendanceNotifier notifier) {
    _scannedTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      notifier.fetchScannedCount();
    });
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    String labelKey = 'name',
    String? Function(Map<String, dynamic>)? labelBuilder,
    required String valueKey,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items.map((item) {
        final id = item[valueKey]?.toString() ?? '';
        final displayText = labelBuilder != null
            ? labelBuilder(item)
            : item[labelKey]?.toString() ?? '';
        return DropdownMenuItem(value: id, child: Text(displayText ?? ''));
      }).toList(),
      onChanged: items.isEmpty ? null : onChanged,
    );
  }
}
