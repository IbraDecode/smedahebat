import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../providers/schedule_provider.dart';
import '../providers/teacher_subject_provider.dart';
import '../widgets/schedule_item_card.dart';

class ScheduleManagementScreen extends ConsumerStatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  ConsumerState<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState
    extends ConsumerState<ScheduleManagementScreen> {
  String? _selectedClassId;
  String? _selectedClassName;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(teacherSubjectProvider.notifier).fetchClasses();
    });
  }

  void _loadSchedule(String classId) {
    ref.read(scheduleProvider.notifier).fetchScheduleByClass(classId);
  }

  Future<void> _deleteSchedule(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: const Text('Yakin ingin menghapus jadwal ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final dio = ref.read(dioProvider);
      try {
        await dio.delete('${ApiEndpoints.schedules}/$id');
        if (_selectedClassId != null) _loadSchedule(_selectedClassId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jadwal berhasil dihapus'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tsState = ref.watch(teacherSubjectProvider);
    final scheduleState = ref.watch(scheduleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kelola Jadwal')),
      floatingActionButton: _selectedClassId != null
          ? FloatingActionButton(
              onPressed: () => context.push('/academic/schedule/create', extra: {
                'classId': _selectedClassId,
                'className': _selectedClassName,
              }),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedClassId,
                isExpanded: true,
                hint: const Text('Pilih Kelas'),
                items: tsState.classes.map((cls) {
                  final id = cls['id']?.toString() ?? '';
                  final name = cls['name'] as String? ?? cls['className'] as String? ?? '';
                  return DropdownMenuItem(
                    value: id,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedClassId = value;
                    final cls = tsState.classes.firstWhere(
                      (c) => c['id']?.toString() == value,
                      orElse: () => <String, dynamic>{},
                    );
                    _selectedClassName =
                        cls['name'] as String? ?? cls['className'] as String? ?? '';
                  });
                  _loadSchedule(value);
                },
              ),
            ),
          ),
          Expanded(
            child: _buildContent(scheduleState, tsState),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ScheduleState scheduleState, TeacherSubjectState tsState) {
    if (_selectedClassId == null) {
      return const EmptyState(
        icon: Icons.class_outlined,
        title: 'Pilih kelas',
        subtitle: 'Pilih kelas untuk melihat jadwal',
      );
    }

    if (scheduleState.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerBox(height: 84),
        ),
      );
    }

    if (scheduleState.error != null) {
      return ErrorState(
        message: scheduleState.error!,
        onRetry: () => _loadSchedule(_selectedClassId!),
      );
    }

    final allItems = <ScheduleItem>[];
    for (final day in Day.values) {
      final items = scheduleState.weeklySchedule[day.name] ?? [];
      allItems.addAll(items);
    }

    if (allItems.isEmpty) {
      return const EmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'Belum ada jadwal',
        subtitle: 'Tambahkan jadwal baru dengan tombol +',
      );
    }

    return _buildWeeklyTable(scheduleState);
  }

  Widget _buildWeeklyTable(ScheduleState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: Day.values.map((day) {
        final items = state.weeklySchedule[day.name] ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: day == Day.current()
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      day.label,
                      style: TextStyle(
                        color: day == Day.current()
                            ? Colors.white
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        'Tidak ada jadwal',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...items.map(
                (item) => ScheduleItemCard(
                  item: item,
                  onTap: () => _showItemActions(item),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  void _showItemActions(ScheduleItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.subjectName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.day.label} | ${item.startTime} - ${item.endTime}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Jadwal'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(
                    '/academic/schedule/${item.id}/edit',
                    extra: {
                      'schedule': item,
                      'classId': _selectedClassId,
                      'className': _selectedClassName,
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Hapus Jadwal',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteSchedule(item.id);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
