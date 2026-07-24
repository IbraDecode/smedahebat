import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TaskCard extends StatelessWidget {
  final String id;
  final String name;
  final String subject;
  final String deadline;
  final String status;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.id,
    required this.name,
    required this.subject,
    required this.deadline,
    required this.status,
    this.onTap,
  });

  Color _statusColor() {
    switch (status) {
      case 'submitted':
        return AppColors.info;
      case 'graded':
        return AppColors.success;
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel() {
    switch (status) {
      case 'submitted':
        return 'Dikumpulkan';
      case 'graded':
        return 'Dinilai';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final urgencyColor = status == 'pending' ? AppColors.warning : AppColors.success;

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
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: urgencyColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
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
                        subject,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        deadline,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _statusLabel(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _statusColor(),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
