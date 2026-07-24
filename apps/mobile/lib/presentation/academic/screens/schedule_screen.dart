import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';

class ScheduleItem {
  final String id;
  final String subject;
  final String teacher;
  final String room;
  final String startTime;
  final String endTime;
  final String day;

  const ScheduleItem({
    required this.id,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.day,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id']?.toString() ?? '',
      subject: json['subject'] as String? ?? '',
      teacher: json['teacher'] as String? ?? '',
      room: json['room'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      day: json['day'] as String? ?? '',
    );
  }
}

class ScheduleState {
  final bool isLoading;
  final String? error;
  final List<ScheduleItem> schedule;
  final int selectedTab;

  const ScheduleState({
    this.isLoading = false,
    this.error,
    this.schedule = const [],
    this.selectedTab = 0,
  });

  ScheduleState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<ScheduleItem>? schedule,
    int? selectedTab,
  }) {
    return ScheduleState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      schedule: schedule ?? this.schedule,
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final Dio _dio;

  ScheduleNotifier(this._dio) : super(const ScheduleState());

  Future<void> fetchSchedule({int? weekOffset}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(
        ApiEndpoints.schedule,
        queryParameters: weekOffset != null ? {'week': weekOffset} : null,
      );
      final List<dynamic> items = response.data['data'] is List
          ? response.data['data'] as List<dynamic>
          : [];
      state = state.copyWith(
        isLoading: false,
        schedule: items
            .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  void setTab(int index) {
    state = state.copyWith(selectedTab: index);
  }
}

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  final dio = ref.watch(dioProvider);
  return ScheduleNotifier(dio)..fetchSchedule();
});

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.selectedTab == 0 ? 'Jadwal Hari Ini' : 'Jadwal Minggu Ini',
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(scheduleProvider.notifier).setTab(0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: state.selectedTab == 0
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Hari Ini',
                        style: TextStyle(
                          color: state.selectedTab == 0
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(scheduleProvider.notifier).setTab(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: state.selectedTab == 1
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Minggu Ini',
                        style: TextStyle(
                          color: state.selectedTab == 1
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? _buildShimmerLoading()
                : state.error != null
                    ? ErrorState(
                        message: state.error!,
                        onRetry: () => ref
                            .read(scheduleProvider.notifier)
                            .fetchSchedule(),
                      )
                    : state.schedule.isEmpty
                        ? const EmptyState(
                            icon: Icons.calendar_today_outlined,
                            title: 'Belum ada jadwal',
                            subtitle: 'Jadwal akan muncul jika sudah tersedia',
                          )
                        : state.selectedTab == 0
                            ? _buildTodayList(context, state.schedule)
                            : _buildWeekGrid(context, state.schedule),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerBox(height: 88),
      ),
    );
  }

  Widget _buildTodayList(BuildContext context, List<ScheduleItem> items) {
    final today = items.where((s) => s.day == 'today').toList();
    if (today.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'Tidak ada jadwal hari ini',
        subtitle: 'Nikmati hari liburmu!',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: today.length,
      itemBuilder: (context, index) => _ScheduleListItem(item: today[index]),
    );
  }

  Widget _buildWeekGrid(BuildContext context, List<ScheduleItem> items) {
    final days = <String, List<ScheduleItem>>{};
    for (final item in items) {
      days.putIfAbsent(item.day, () => []).add(item);
    }

    if (days.isEmpty) {
      return const EmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'Belum ada jadwal',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: days.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              ...entry.value.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ScheduleListItem(item: item),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ScheduleListItem extends StatelessWidget {
  final ScheduleItem item;

  const _ScheduleListItem({required this.item});

  @override
  Widget build(BuildContext context) {
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
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  item.startTime.split(':').first,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  item.startTime.split(':').last,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.subject,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      item.teacher,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.room_outlined, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      item.room,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${item.startTime}-${item.endTime}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        ],
      ),
    );
  }
}
