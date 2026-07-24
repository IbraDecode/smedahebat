import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_provider.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../../academic/providers/schedule_provider.dart';
import '../providers/picket_provider.dart';
import '../widgets/picket_member_tile.dart';
import '../../../core/constants/app_colors.dart';

class PicketManageScreen extends ConsumerStatefulWidget {
  const PicketManageScreen({super.key});

  @override
  ConsumerState<PicketManageScreen> createState() => _PicketManageScreenState();
}

class _PicketManageScreenState extends ConsumerState<PicketManageScreen> {
  Day _selectedDay = Day.current();
  String? _classId;
  final Set<String> _selectedStudentIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.role == 'teacher' || auth.role == 'admin') {
        if (_classId != null) {
          ref.read(picketProvider.notifier).fetchClassSchedule(_classId!);
          ref.read(picketProvider.notifier).fetchClassMembers(_classId!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(picketProvider);
    final auth = ref.watch(authProvider);
    final isTeacher = auth.role == 'teacher' || auth.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Piket'),
        actions: [
          if (_classId != null)
            TextButton(
              onPressed: _selectedStudentIds.isNotEmpty ? _handleAssign : null,
              child: const Text('Simpan'),
            ),
        ],
      ),
      body: !isTeacher
          ? const Center(child: Text('Akses terbatas'))
          : _classId == null
              ? _buildClassSelector()
              : state.isLoading && state.classSchedule.isEmpty
                  ? _buildShimmer()
                  : state.error != null && state.classSchedule.isEmpty
                      ? ErrorState(
                          message: state.error!,
                          onRetry: () {
                            ref.read(picketProvider.notifier).fetchClassSchedule(_classId!);
                          },
                        )
                      : _buildContent(context, state),
    );
  }

  Widget _buildClassSelector() {
    final classes = <String>['X-A', 'X-B', 'XI-A', 'XI-B', 'XII-A', 'XII-B'];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: classes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final c = classes[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.meeting_room_outlined),
            title: Text(c),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              setState(() => _classId = c);
              ref.read(picketProvider.notifier).fetchClassSchedule(c);
              ref.read(picketProvider.notifier).fetchClassMembers(c);
            },
          ),
        );
      },
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

  Widget _buildContent(BuildContext context, PicketState state) {
    return Column(
      children: [
        _buildDaySelector(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentSchedule(state),
                const SizedBox(height: 24),
                _buildStudentSelector(state),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: Day.values.map((day) {
          final isSelected = day == _selectedDay;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(day.label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedDay = day),
              selectedColor: _dayColor(day).withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? _dayColor(day) : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentSchedule(PicketState state) {
    final daySchedule = state.classSchedule.where(
      (d) => d.day == _selectedDay,
    ).toList();

    if (daySchedule.isEmpty || daySchedule.first.members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.people_outline, size: 40, color: AppColors.textHint),
            const SizedBox(height: 8),
            Text(
              'Belum ada anggota piket untuk ${_selectedDay.label}',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Anggota Piket ${_selectedDay.label}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            const Spacer(),
            Text(
              '${daySchedule.first.members.length} orang',
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: daySchedule.first.members.length,
          onReorder: (oldIndex, newIndex) {
            final members = List<PicketMember>.from(daySchedule.first.members);
            final item = members.removeAt(oldIndex);
            members.insert(newIndex, item);
            ref.read(picketProvider.notifier).reorderMembers(_selectedDay.name, members);
          },
          itemBuilder: (context, index) {
            final member = daySchedule.first.members[index];
                return Row(
                  key: ValueKey(member.id),
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.drag_handle, color: AppColors.textHint),
                      ),
                    ),
                Expanded(child: PicketMemberTile(member: member, dense: true)),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                  onPressed: () => _handleRemove(member.id),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStudentSelector(PicketState state) {
    if (state.classMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tambah Anggota',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: state.classMembers.map((member) {
            final selected = _selectedStudentIds.contains(member.id);
            return FilterChip(
              label: Text(member.name),
              selected: selected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedStudentIds.add(member.id);
                  } else {
                    _selectedStudentIds.remove(member.id);
                  }
                });
              },
              avatar: CircleAvatar(
                radius: 12,
                backgroundColor: selected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.surfaceVariant,
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
              selectedColor: AppColors.primary.withValues(alpha: 0.12),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
        if (_selectedStudentIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _handleAssign,
              icon: const Icon(Icons.person_add, size: 18),
              label: Text(
                'Tugaskan ke ${_selectedDay.label} (${_selectedStudentIds.length})',
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleRemove(String picketId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Anggota'),
        content: const Text('Yakin ingin menghapus anggota piket ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final error = await ref.read(picketProvider.notifier).removePicket(picketId);
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  Future<void> _handleAssign() async {
    if (_classId == null || _selectedStudentIds.isEmpty) return;
    final error = await ref.read(picketProvider.notifier).createPicket(
      classId: _classId!,
      day: _selectedDay.name,
      studentIds: _selectedStudentIds.toList(),
    );
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      setState(() => _selectedStudentIds.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anggota piket berhasil ditambahkan')),
        );
      }
    }
  }

  Color _dayColor(Day day) {
    switch (day) {
      case Day.senin:
        return AppColors.primary;
      case Day.selasa:
        return AppColors.success;
      case Day.rabu:
        return AppColors.warning;
      case Day.kamis:
        return AppColors.secondary;
      case Day.jumat:
        return AppColors.accent;
      case Day.sabtu:
        return AppColors.info;
    }
  }
}
