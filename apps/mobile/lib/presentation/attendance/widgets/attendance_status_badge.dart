import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AttendanceStatusBadge extends StatelessWidget {
  final String status;
  final bool isSmall;

  const AttendanceStatusBadge({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: isSmall ? 12 : 16, color: config.color),
          if (isSmall) const SizedBox(width: 4) else const SizedBox(width: 6),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontWeight: FontWeight.w600,
              fontSize: isSmall ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getConfig(String status) {
    switch (status.toUpperCase()) {
      case 'HADIR':
        return _StatusConfig(AppColors.success, Icons.check_circle, 'Hadir');
      case 'SAKIT':
        return _StatusConfig(AppColors.warning, Icons.medical_services_outlined, 'Sakit');
      case 'IZIN':
        return _StatusConfig(AppColors.info, Icons.description_outlined, 'Izin');
      case 'ALPA':
        return _StatusConfig(AppColors.error, Icons.cancel_outlined, 'Alpa');
      case 'TERLAMBAT':
        return _StatusConfig(
          AppColors.secondary,
          Icons.access_time,
          'Terlambat',
        );
      default:
        return _StatusConfig(AppColors.textHint, Icons.help_outline, status);
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String label;

  const _StatusConfig(this.color, this.icon, this.label);
}
