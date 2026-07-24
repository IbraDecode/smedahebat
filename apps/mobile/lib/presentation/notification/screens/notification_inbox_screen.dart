import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_tile.dart';

class NotificationInboxScreen extends ConsumerStatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  ConsumerState<NotificationInboxScreen> createState() => _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends ConsumerState<NotificationInboxScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(notificationProvider);
      if (!state.isLoadingMore && state.hasMore) {
        ref.read(notificationProvider.notifier).fetchNotifications(page: state.page + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (state.notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () => ref.read(notificationProvider.notifier).markAllRead(),
              child: const Text('Tandai Dibaca'),
            ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(NotificationState state) {
    if (state.isLoading) {
      return _buildShimmer();
    }

    if (state.error != null && state.notifications.isEmpty) {
      return ErrorState(
        message: state.error!,
        onRetry: () => ref.read(notificationProvider.notifier).fetchNotifications(),
      );
    }

    if (state.notifications.isEmpty) {
      return EmptyState(
        icon: Icons.notifications_off_outlined,
        title: 'Tidak ada notifikasi',
        subtitle: 'Notifikasi akan muncul di sini',
      );
    }

    final grouped = _groupNotifications(state.notifications);

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: grouped.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= grouped.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final entry = grouped.entries.elementAt(index);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              ...entry.value.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: NotificationTile(
                      item: item,
                      onTap: () {
                        ref.read(notificationProvider.notifier).markRead(item.id);
                        _handleNotificationTap(context, item);
                      },
                      onDismiss: () {
                        ref.read(notificationProvider.notifier).markRead(item.id);
                      },
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  Map<String, List<NotificationItem>> _groupNotifications(List<NotificationItem> items) {
    final grouped = <String, List<NotificationItem>>{};
    final now = DateTime.now();

    for (final item in items) {
      final diff = now.difference(item.createdAt);
      String label;
      if (diff.inDays == 0) {
        label = 'Hari Ini';
      } else if (diff.inDays < 7) {
        label = 'Minggu Ini';
      } else {
        label = 'Sebelumnya';
      }
      grouped.putIfAbsent(label, () => []).add(item);
    }

    final ordered = <String, List<NotificationItem>>{};
    for (final key in ['Hari Ini', 'Minggu Ini', 'Sebelumnya']) {
      if (grouped.containsKey(key)) {
        ordered[key] = grouped[key]!;
      }
    }

    return ordered;
  }

  void _handleNotificationTap(BuildContext context, NotificationItem item) {
    switch (item.type) {
      case NotificationType.announcement:
        if (item.relatedId != null) {
          context.push('/announcements/${item.relatedId}');
        }
      case NotificationType.task:
      case NotificationType.grade:
      case NotificationType.attendance:
      case NotificationType.system:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notifikasi: ${item.title}')),
        );
    }
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ShimmerLoading.listItem(height: 68),
      ),
    );
  }
}
