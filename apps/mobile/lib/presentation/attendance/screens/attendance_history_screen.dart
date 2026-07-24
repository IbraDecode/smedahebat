import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../academic/providers/teacher_subject_provider.dart';
import '../../auth/auth_provider.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../providers/attendance_provider.dart';
import '../widgets/attendance_list_item.dart';
import '../widgets/attendance_status_badge.dart';

class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  final String? classId;

  const AttendanceHistoryScreen({super.key, this.classId});

  @override
  ConsumerState<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends ConsumerState<AttendanceHistoryScreen> {
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final role = ref.read(authProvider).role;
      if (role == 'student') {
        ref.read(attendanceProvider.notifier).fetchMyAttendance();
      } else {
        ref.read(teacherSubjectProvider.notifier).fetchClasses();
      }
      if (widget.classId != null) {
        _selectedClassId = widget.classId;
        ref.read(attendanceProvider.notifier).fetchClassAttendance(widget.classId!);
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
        title: Text(isStudent ? 'Riwayat Absensi' : 'Absensi Kelas'),
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
                  if (v != null) notifier.fetchClassAttendance(v);
                },
              ),
            ),
          Expanded(
            child: state.isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 6,
                    itemBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ShimmerBox(height: 72),
                    ),
                  )
                : state.error != null
                    ? ErrorState(
                        message: state.error!,
                        onRetry: () => isStudent
                            ? notifier.fetchMyAttendance()
                            : _selectedClassId != null
                                ? notifier
                                    .fetchClassAttendance(_selectedClassId!)
                                : null,
                      )
                    : RefreshIndicator(
                        onRefresh: isStudent
                            ? notifier.fetchMyAttendance
                            : () async {
                                if (_selectedClassId != null) {
                                  await notifier
                                      .fetchClassAttendance(_selectedClassId!);
                                }
                              },
                        child: state.records == null || state.records!.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 80),
                                  EmptyState(
                                    icon: Icons.how_to_reg_outlined,
                                    title: 'Belum ada riwayat absensi',
                                    subtitle:
                                        'Data absensi akan muncul setelah guru melakukan presensi',
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: state.records!.length,
                                itemBuilder: (context, index) {
                                  final record = state.records![index];
                                  return AttendanceListItem(
                                    record: record,
                                    onTap: () {
                                      _showRecordDetail(context, record);
                                    },
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showRecordDetail(BuildContext context, dynamic record) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Detail Absensi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              _detailRow('Mata Pelajaran', record.subject),
              _detailRow('Tanggal', record.date),
              if (record.time.isNotEmpty) _detailRow('Waktu', record.time),
              if (record.className != null)
                _detailRow('Kelas', record.className!),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Status: ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AttendanceStatusBadge(
                    status: record.status as String,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
