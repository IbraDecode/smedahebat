import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

String gradeLetter(double score) {
  if (score >= 90) return 'A';
  if (score >= 75) return 'B';
  if (score >= 60) return 'C';
  if (score >= 50) return 'D';
  return 'E';
}

Color gradeColor(double score) {
  if (score >= 90) return AppColors.success;
  if (score >= 75) return AppColors.info;
  if (score >= 60) return AppColors.warning;
  if (score >= 50) return AppColors.accent;
  return AppColors.error;
}

class GradeBadge extends StatelessWidget {
  final double score;
  final double? size;

  const GradeBadge({super.key, required this.score, this.size});

  @override
  Widget build(BuildContext context) {
    final letter = gradeLetter(score);
    final color = gradeColor(score);
    final s = size ?? 36;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(s / 3),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: s * 0.5,
        ),
      ),
    );
  }
}
