import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';

class QrDisplay extends StatefulWidget {
  final String token;
  final int expiresInSeconds;
  final VoidCallback onExpired;
  final VoidCallback? onStop;

  const QrDisplay({
    super.key,
    required this.token,
    required this.expiresInSeconds,
    required this.onExpired,
    this.onStop,
  });

  @override
  State<QrDisplay> createState() => _QrDisplayState();
}

class _QrDisplayState extends State<QrDisplay>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  late Timer _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _remaining = widget.expiresInSeconds;
    _startTimer();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 0) {
        timer.cancel();
        widget.onExpired();
        return;
      }
      setState(() => _remaining--);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final isExpired = _remaining <= 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1 + _pulseController.value * 0.15),
                    blurRadius: 30 + _pulseController.value * 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: widget.token,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF1E3A5F),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF1E3A5F),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isExpired ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isExpired ? Icons.timer_off : Icons.timer_outlined,
                color: isExpired ? AppColors.error : AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isExpired ? 'Kedaluwarsa' : timeStr,
                style: TextStyle(
                  color: isExpired ? AppColors.error : AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isExpired
                        ? AppColors.error
                        : AppColors.success.withValues(
                            alpha: 0.4 + _pulseController.value * 0.6,
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isExpired ? 'Sesi berakhir' : 'Menunggu scan...',
                  style: TextStyle(
                    color: isExpired ? AppColors.error : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            );
          },
        ),
        if (widget.onStop != null && !isExpired) ...[
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: widget.onStop,
            icon: const Icon(Icons.stop_circle_outlined, size: 18),
            label: const Text('Stop Sesi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ],
    );
  }
}
