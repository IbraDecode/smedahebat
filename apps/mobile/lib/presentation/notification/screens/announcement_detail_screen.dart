import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/auth_provider.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../providers/notification_provider.dart';
import '../widgets/target_badge.dart';

class AnnouncementDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const AnnouncementDetailScreen({super.key, required this.id});

  @override
  ConsumerState<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends ConsumerState<AnnouncementDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).fetchAnnouncementDetail(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final auth = ref.watch(authProvider);
    final item = state.selectedAnnouncement;

    final isAdmin = auth.role == 'admin';
    final isAuthor = item?.authorId == auth.nis;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengumuman'),
        actions: [
          if (item != null && isAdmin)
            IconButton(
              icon: Icon(
                item.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: item.isPinned ? AppColors.accent : null,
              ),
              onPressed: () {
                ref.read(notificationProvider.notifier).togglePin(item.id, !item.isPinned);
              },
            ),
          if (item != null && (isAdmin || isAuthor))
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, item.id),
            ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur bagikan akan segera hadir')),
              );
            },
          ),
        ],
      ),
      body: state.isLoading
          ? _buildShimmer()
          : state.error != null
              ? ErrorState(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(notificationProvider.notifier).fetchAnnouncementDetail(widget.id),
                )
              : item != null
                  ? _buildContent(context, item)
                  : const Center(child: Text('Data tidak ditemukan')),
    );
  }

  Widget _buildContent(BuildContext context, AnnouncementItem item) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (item.isPinned) ...[
                Icon(Icons.push_pin, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
              ],
              TargetBadge(target: item.target, targetClass: item.targetClass),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  item.authorName.isNotEmpty ? item.authorName[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.authorName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    _formatDateTime(item.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
                ],
              ),
            ],
          ),
          if (item.attachments.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Lampiran',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ...item.attachments.map((url) => _buildAttachmentTile(context, url)),
          ],
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            item.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(BuildContext context, String url) {
    final fileName = url.split('/').last;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download, size: 18),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unduhan akan segera hadir')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 80, height: 20),
          const SizedBox(height: 12),
          ShimmerBox(height: 28),
          const SizedBox(height: 16),
          Row(
            children: [
              ShimmerBox(width: 36, height: 36, borderRadius: 18),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 120, height: 14),
                  const SizedBox(height: 4),
                  ShimmerBox(width: 80, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ShimmerBox(height: 200),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengumuman'),
        content: const Text('Apakah Anda yakin ingin menghapus pengumuman ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(notificationProvider.notifier).deleteAnnouncement(id);
              context.pop();
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
