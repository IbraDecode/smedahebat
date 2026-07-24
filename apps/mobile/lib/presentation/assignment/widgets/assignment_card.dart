import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/assignment_provider.dart';
import 'submission_status_badge.dart';

class AssignmentCard extends StatelessWidget {
  final AssignmentItem item;
  final VoidCallback? onTap;

  const AssignmentCard({
    super.key,
    required this.item,
    this.onTap,
  });

  String _deadlineLabel() {
    final now = DateTime.now();
    final diff = item.deadline.difference(now);
    final totalDays = diff.inDays;
    final totalHours = diff.inHours;

    if (totalDays < 0) {
      return 'Terlambat ${(-totalDays).abs()} hari';
    } else if (totalDays == 0) {
      if (totalHours <= 0) {
        return 'Batas waktu hari ini';
      }
      return 'Tersisa $totalHours jam';
    } else if (totalDays == 1) {
      return 'Tersisa 1 hari';
    } else if (totalDays <= 7) {
      return 'Tersisa $totalDays hari';
    } else {
      return DateFormat('d MMM', 'id').format(item.deadline);
    }
  }

  Color _deadlineColor() {
    final now = DateTime.now();
    final diff = item.deadline.difference(now);
    final totalDays = diff.inDays;

    if (totalDays < 0 || (totalDays == 0 && diff.inHours < 0)) {
      return AppColors.error;
    } else if (totalDays == 0) {
      return AppColors.warning;
    } else if (totalDays == 1) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _subjectColor(),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.book_outlined, size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            item.subjectName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          if (item.className.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.meeting_room_outlined, size: 14, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(
                              item.className,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: _deadlineColor()),
                const SizedBox(width: 4),
                Text(
                  _deadlineLabel(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _deadlineColor(),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const Spacer(),
                if (item.myStatus != null)
                  SubmissionStatusBadge(status: item.myStatus!)
                else
                  _buildSubmissionCount(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _subjectColor() {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
    ];
    return colors[item.subjectName.hashCode % colors.length];
  }

  Widget _buildSubmissionCount(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            '${item.gradedCount}/${item.totalSubmissions}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
