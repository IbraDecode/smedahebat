import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/auth_provider.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../providers/notification_provider.dart';
import '../widgets/announcement_card.dart';

class AnnouncementListScreen extends ConsumerStatefulWidget {
  const AnnouncementListScreen({super.key});

  @override
  ConsumerState<AnnouncementListScreen> createState() => _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends ConsumerState<AnnouncementListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).fetchAnnouncements();
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
        ref.read(notificationProvider.notifier).fetchAnnouncements(page: state.page + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final auth = ref.watch(authProvider);
    final canCreate = auth.role == 'teacher' || auth.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumuman'),
        actions: [
          _buildFilterChips(state),
        ],
      ),
      body: _buildBody(state),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => context.push('/announcements/create'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildFilterChips(NotificationState state) {
    return PopupMenuButton<AnnouncementTarget?>(
      icon: const Icon(Icons.filter_list),
      onSelected: (target) {
        ref.read(notificationProvider.notifier).setFilter(target);
        ref.read(notificationProvider.notifier).fetchAnnouncements();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: null,
          child: Text('Semua', style: TextStyle(fontWeight: state.filterTarget == null ? FontWeight.bold : FontWeight.normal)),
        ),
        PopupMenuItem(
          value: AnnouncementTarget.all,
          child: Text('Umum', style: TextStyle(fontWeight: state.filterTarget == AnnouncementTarget.all ? FontWeight.bold : FontWeight.normal)),
        ),
        PopupMenuItem(
          value: AnnouncementTarget.siswa,
          child: Text('Siswa', style: TextStyle(fontWeight: state.filterTarget == AnnouncementTarget.siswa ? FontWeight.bold : FontWeight.normal)),
        ),
        PopupMenuItem(
          value: AnnouncementTarget.guru,
          child: Text('Guru', style: TextStyle(fontWeight: state.filterTarget == AnnouncementTarget.guru ? FontWeight.bold : FontWeight.normal)),
        ),
        PopupMenuItem(
          value: AnnouncementTarget.waliKelas,
          child: Text('Wali Kelas', style: TextStyle(fontWeight: state.filterTarget == AnnouncementTarget.waliKelas ? FontWeight.bold : FontWeight.normal)),
        ),
      ],
    );
  }

  Widget _buildBody(NotificationState state) {
    if (state.isLoading) {
      return _buildShimmer();
    }

    if (state.error != null && state.announcements.isEmpty) {
      return ErrorState(
        message: state.error!,
        onRetry: () => ref.read(notificationProvider.notifier).fetchAnnouncements(),
      );
    }

    if (state.announcements.isEmpty) {
      return EmptyState(
        icon: Icons.campaign_outlined,
        title: 'Belum ada pengumuman',
        subtitle: 'Pengumuman akan muncul di sini',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationProvider.notifier).fetchAnnouncements(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: state.announcements.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.announcements.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = state.announcements[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AnnouncementCard(
              item: item,
              onTap: () {
                ref.read(notificationProvider.notifier).markAnnouncementRead(item.id);
                context.push('/announcements/${item.id}');
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ShimmerLoading.listItem(height: 80),
      ),
    );
  }
}
