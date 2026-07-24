import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/notification_provider.dart';

class TargetBadge extends StatelessWidget {
  final AnnouncementTarget target;
  final String? targetClass;

  const TargetBadge({
    super.key,
    required this.target,
    this.targetClass,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: config.color,
        ),
      ),
    );
  }

  _BadgeConfig _getConfig() {
    switch (target) {
      case AnnouncementTarget.all:
        return _BadgeConfig('Semua', AppColors.info);
      case AnnouncementTarget.siswa:
        return _BadgeConfig('Siswa', AppColors.success);
      case AnnouncementTarget.guru:
        return _BadgeConfig('Guru', AppColors.warning);
      case AnnouncementTarget.waliKelas:
        return _BadgeConfig('Wali Kelas', AppColors.secondary);
      case AnnouncementTarget.kelas:
        return _BadgeConfig(targetClass ?? 'Kelas', AppColors.accent);
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color color;

  const _BadgeConfig(this.label, this.color);
}
