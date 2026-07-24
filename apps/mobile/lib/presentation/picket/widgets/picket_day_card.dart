import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../academic/providers/schedule_provider.dart';
import '../providers/picket_provider.dart';

class PicketDayCard extends StatelessWidget {
  final Day day;
  final bool isToday;
  final List<PicketMember> members;
  final VoidCallback? onTap;
  final Widget? trailing;

  const PicketDayCard({
    super.key,
    required this.day,
    this.isToday = false,
    this.members = const [],
    this.onTap,
    this.trailing,
  });

  Color get _dayColor {
    switch (day) {
      case Day.senin:
        return AppColors.primary;
      case Day.selasa:
        return AppColors.success;
      case Day.rabu:
        return AppColors.warning;
      case Day.kamis:
        return AppColors.secondary;
      case Day.jumat:
        return AppColors.accent;
      case Day.sabtu:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = members.where((m) => m.isDone).length;
    final completionPercent = members.isEmpty
        ? 0.0
        : doneCount / members.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isToday ? 2 : 0,
      shadowColor: _dayColor.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isToday ? _dayColor : AppColors.border,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _dayColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            day.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _dayColor,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _dayColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Hari Ini',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _dayColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${members.length} anggota',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (trailing != null) trailing!,
                  if (trailing == null)
                    _buildCompletionBadge(completionPercent, doneCount),
                ],
              ),
              if (members.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completionPercent,
                    minHeight: 4,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      completionPercent >= 1 ? AppColors.success : _dayColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: members.take(5).map((m) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: m.isDone
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        m.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: m.isDone ? AppColors.success : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (members.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${members.length - 5} lainnya',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionBadge(double percent, int doneCount) {
    if (members.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.textHint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Kosong',
          style: TextStyle(fontSize: 11, color: AppColors.textHint),
        ),
      );
    }
    if (percent >= 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: AppColors.success),
            SizedBox(width: 4),
            Text(
              'Semua Selesai',
              style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }
    if (doneCount > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$doneCount/${members.length} Selesai',
          style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w500),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textHint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${members.length} anggota',
        style: const TextStyle(fontSize: 11, color: AppColors.textHint),
      ),
    );
  }
}
