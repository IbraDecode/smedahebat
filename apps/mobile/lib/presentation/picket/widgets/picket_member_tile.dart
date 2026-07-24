import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/picket_provider.dart';

class PicketMemberTile extends StatelessWidget {
  final PicketMember member;
  final bool showCheckbox;
  final bool showTime;
  final bool checked;
  final VoidCallback? onToggle;
  final bool dense;

  const PicketMemberTile({
    super.key,
    required this.member,
    this.showCheckbox = false,
    this.showTime = true,
    this.checked = false,
    this.onToggle,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: dense ? 3 : 4,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: member.isDone ? AppColors.success.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: dense ? 10 : 14,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: dense ? 16 : 20,
                backgroundColor: member.isDone
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.surfaceVariant,
                child: Text(
                  member.name.isNotEmpty
                      ? member.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: member.isDone ? AppColors.success : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: dense ? 13 : 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: TextStyle(
                        fontSize: dense ? 13 : 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        decoration: member.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (member.nis != null)
                      Text(
                        member.nis!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                  ],
                ),
              ),
              if (showCheckbox)
                Checkbox(
                  value: checked,
                  onChanged: (_) => onToggle?.call(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  activeColor: AppColors.success,
                ),
              if (!showCheckbox && member.isDone)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                      if (showTime && member.doneAt != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(member.doneAt!),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (!member.isDone && !showCheckbox)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (showCheckbox && onToggle == null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: member.isDone
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.textHint.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    member.isDone ? 'Selesai' : 'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      color: member.isDone ? AppColors.success : AppColors.textHint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
