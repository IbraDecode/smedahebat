import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class RoleBadge extends StatelessWidget {
  final String role;
  final bool isSmall;

  const RoleBadge({super.key, required this.role, this.isSmall = false});

  static Color colorForRole(String role) {
    switch (role) {
      case 'ADMIN':
        return AppColors.error;
      case 'GURU':
        return Colors.blue;
      case 'WALI_KELAS':
        return AppColors.secondary;
      case 'SISWA':
        return AppColors.success;
      case 'BK':
        return AppColors.warning;
      case 'TU':
        return Colors.teal;
      case 'KEPALA_SEKOLAH':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  static String labelForRole(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Admin';
      case 'GURU':
        return 'Guru';
      case 'WALI_KELAS':
        return 'Wali Kelas';
      case 'SISWA':
        return 'Siswa';
      case 'BK':
        return 'BK';
      case 'TU':
        return 'TU';
      case 'KEPALA_SEKOLAH':
        return 'Kepala Sekolah';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorForRole(role);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        labelForRole(role),
        style: TextStyle(
          fontSize: isSmall ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
