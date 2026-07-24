import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/assignment_provider.dart';

class SubmissionStatusBadge extends StatelessWidget {
  final SubmissionStatus status;
  final double fontSize;

  const SubmissionStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
  });

  Color _color() {
    switch (status) {
      case SubmissionStatus.pending:
        return AppColors.textHint;
      case SubmissionStatus.submitted:
        return AppColors.info;
      case SubmissionStatus.late:
        return AppColors.error;
      case SubmissionStatus.graded:
        return AppColors.success;
    }
  }

  Color _bgColor() {
    return _color().withValues(alpha: 0.1);
  }

  String _label() {
    switch (status) {
      case SubmissionStatus.pending:
        return 'Belum Dikumpulkan';
      case SubmissionStatus.submitted:
        return 'Terkirim';
      case SubmissionStatus.late:
        return 'Terlambat';
      case SubmissionStatus.graded:
        return 'Dinilai';
    }
  }

  IconData _icon() {
    switch (status) {
      case SubmissionStatus.pending:
        return Icons.schedule_outlined;
      case SubmissionStatus.submitted:
        return Icons.check_circle_outline;
      case SubmissionStatus.late:
        return Icons.error_outline;
      case SubmissionStatus.graded:
        return Icons.grading_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor(),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: fontSize, color: _color()),
          const SizedBox(width: 4),
          Text(
            _label(),
            style: TextStyle(
              fontSize: fontSize,
              color: _color(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
