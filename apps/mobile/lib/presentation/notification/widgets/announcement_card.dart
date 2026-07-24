import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/notification_provider.dart';
import 'target_badge.dart';

class AnnouncementCard extends StatelessWidget {
  final AnnouncementItem item;
  final VoidCallback? onTap;

  const AnnouncementCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? AppColors.surface : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isRead ? Colors.transparent : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.isPinned) ...[
                        Icon(Icons.push_pin, size: 14, color: AppColors.accent),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: item.isRead ? FontWeight.normal : FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TargetBadge(target: item.target, targetClass: item.targetClass),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.content,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        item.authorName,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(item.createdAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${date.day}/${date.month}/${date.year}';
  }
}
