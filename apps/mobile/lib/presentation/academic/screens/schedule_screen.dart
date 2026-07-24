import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../providers/schedule_provider.dart';
import '../widgets/day_selector.dart';
import '../widgets/schedule_item_card.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(scheduleProvider.notifier).fetchTodaySchedule());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleProvider);
    final notifier = ref.read(scheduleProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.view == ScheduleView.daily ? 'Jadwal Hari Ini' : 'Jadwal Minggu Ini',
        ),
      ),
      body: Column(
        children: [
          _buildSegmentedControl(state, notifier),
          if (state.view == ScheduleView.weekly) ...[
            const SizedBox(height: 8),
            DaySelector(
              selectedDay: state.selectedDay,
              onDaySelected: (day) => notifier.setSelectedDay(day),
            ),
          ],
          const SizedBox(height: 4),
          Expanded(
            child: state.isLoading
                ? _buildShimmerList()
                : state.error != null
                    ? ErrorState(
                        message: state.error!,
                        onRetry: () => notifier.fetchTodaySchedule(),
                      )
                    : RefreshIndicator(
                        onRefresh: () => notifier.fetchTodaySchedule(),
                        child: state.view == ScheduleView.daily
                            ? _buildDailyView(context, state)
                            : _buildWeeklyView(context, state),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(ScheduleState state, ScheduleNotifier notifier) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => notifier.setView(ScheduleView.daily),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: state.view == ScheduleView.daily
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Hari Ini',
                  style: TextStyle(
                    color: state.view == ScheduleView.daily
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
              onTap: () => notifier.setView(ScheduleView.weekly),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: state.view == ScheduleView.weekly
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Minggu Ini',
                  style: TextStyle(
                    color: state.view == ScheduleView.weekly
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
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerBox(height: 84),
      ),
    );
  }

  Widget _buildDailyView(BuildContext context, ScheduleState state) {
    final items = List<ScheduleItem>.from(state.todaySchedule)
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    if (items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          EmptyState(
            icon: Icons.check_circle_outline,
            title: 'Tidak ada jadwal hari ini',
            subtitle: 'Nikmati hari liburmu!',
          ),
        ],
      );
    }

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    int? currentIndex;
    int? nextIndex;

    for (int i = 0; i < items.length; i++) {
      if (currentMinutes >= items[i].startMinutes &&
          currentMinutes < items[i].endMinutes) {
        currentIndex = i;
        break;
      }
      if (items[i].startMinutes > currentMinutes) {
        nextIndex = i;
        break;
      }
    }

    if (currentIndex == null && nextIndex == null && items.isNotEmpty) {
      if (currentMinutes < items.first.startMinutes) {
        nextIndex = 0;
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildTimeIndicator(items, currentMinutes);
        }
        final i = index - 1;
        final item = items[i];
        return ScheduleItemCard(
          item: item,
          isCurrent: i == currentIndex,
          isNext: i == nextIndex && currentIndex == null,
        );
      },
    );
  }

  Widget _buildTimeIndicator(List<ScheduleItem> items, int currentMinutes) {
    final currentHour = currentMinutes ~/ 60;
    final currentMin = currentMinutes % 60;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${currentHour.toString().padLeft(2, '0')}:${currentMin.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(height: 1, color: AppColors.primary.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyView(BuildContext context, ScheduleState state) {
    final selectedDayItems = state.weeklySchedule[state.selectedDay.name] ?? [];

    if (selectedDayItems.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          EmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'Tidak ada jadwal',
            subtitle: 'Tidak ada pelajaran di hari ${state.selectedDay.label}',
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: selectedDayItems.length,
      itemBuilder: (context, index) => ScheduleItemCard(
        item: selectedDayItems[index],
      ),
    );
  }
}
