import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/auth_provider.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../providers/picket_provider.dart';
import '../widgets/picket_day_card.dart';

class PicketScheduleScreen extends ConsumerStatefulWidget {
  const PicketScheduleScreen({super.key});

  @override
  ConsumerState<PicketScheduleScreen> createState() => _PicketScheduleScreenState();
}

class _PicketScheduleScreenState extends ConsumerState<PicketScheduleScreen> {
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.role == 'student') {
        ref.read(picketProvider.notifier).fetchMySchedule();
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
        title: const Text('Jadwal Piket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat',
            onPressed: () => context.push('/picket/history'),
          ),
          if (isTeacher)
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Cek Piket Hari Ini',
              onPressed: () => context.push('/picket/checklist'),
            ),
        ],
      ),
      body: state.isLoading && state.mySchedule.isEmpty && state.classSchedule.isEmpty
          ? _buildShimmer()
          : state.error != null && state.mySchedule.isEmpty && state.classSchedule.isEmpty
              ? ErrorState(
                  message: state.error!,
                  onRetry: () {
                    if (isTeacher && _selectedClassId != null) {
                      ref.read(picketProvider.notifier).fetchClassSchedule(_selectedClassId!);
                    } else {
                      ref.read(picketProvider.notifier).fetchMySchedule();
                    }
                  },
                )
              : _buildContent(context, ref, state, auth, isTeacher),
      floatingActionButton: isTeacher
          ? FloatingActionButton(
              onPressed: () => context.push('/picket/manage'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerLoading.listItem(height: 100),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    PicketState state,
    AuthState auth,
    bool isTeacher,
  ) {
    if (isTeacher) {
      return _buildTeacherView(context, ref, state, auth);
    }
    return _buildStudentView(context, state);
  }

  Widget _buildStudentView(BuildContext context, PicketState state) {
    if (state.mySchedule.isEmpty) {
      return const EmptyState(
        icon: Icons.calendar_view_week_outlined,
        title: 'Belum ada jadwal piket',
        subtitle: 'Hubungi wali kelas untuk informasi jadwal piket',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(picketProvider.notifier).fetchMySchedule(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
        itemCount: state.mySchedule.length,
        itemBuilder: (context, index) {
          final picketDay = state.mySchedule[index];
          return PicketDayCard(
            day: picketDay.day,
            isToday: picketDay.isToday,
            members: picketDay.members,
            onTap: picketDay.isToday && picketDay.members.isNotEmpty
                ? () => context.push('/picket/checklist')
                : null,
          );
        },
      ),
    );
  }

  Widget _buildTeacherView(
    BuildContext context,
    WidgetRef ref,
    PicketState state,
    AuthState auth,
  ) {
    return Column(
      children: [
        _buildClassSelector(ref, auth),
        Expanded(
          child: state.classSchedule.isEmpty
              ? const EmptyState(
                  icon: Icons.calendar_view_week_outlined,
                  title: 'Belum ada jadwal piket',
                  subtitle: 'Tekan + untuk menambah jadwal piket',
                )
              : RefreshIndicator(
                  onRefresh: () {
                    if (_selectedClassId != null) {
                      return ref.read(picketProvider.notifier).fetchClassSchedule(_selectedClassId!);
                    }
                    return Future.value();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 80),
                    itemCount: state.classSchedule.length,
                    itemBuilder: (context, index) {
                      final picketDay = state.classSchedule[index];
                      return PicketDayCard(
                        day: picketDay.day,
                        isToday: picketDay.isToday,
                        members: picketDay.members,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: AppColors.textHint,
                          onPressed: () => context.push('/picket/manage'),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildClassSelector(WidgetRef ref, AuthState auth) {
    if (_selectedClassId == null && auth.role == 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showClassPicker(ref));
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => _showClassPicker(ref),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.school_outlined, color: AppColors.textHint, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selectedClassId ?? 'Pilih Kelas',
                  style: TextStyle(
                    color: _selectedClassId != null ? AppColors.textPrimary : AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  void _showClassPicker(WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _ClassPickerSheet(
        onSelected: (classId) {
          setState(() => _selectedClassId = classId);
          ref.read(picketProvider.notifier).fetchClassSchedule(classId);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _ClassPickerSheet extends ConsumerWidget {
  final ValueChanged<String> onSelected;

  const _ClassPickerSheet({required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = <String>['X-A', 'X-B', 'XI-A', 'XI-B', 'XII-A', 'XII-B'];
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Kelas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          ...classes.map((c) => ListTile(
                leading: const Icon(Icons.meeting_room_outlined),
                title: Text(c),
                onTap: () => onSelected(c),
              )),
        ],
      ),
    );
  }
}
