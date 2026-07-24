import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                AppColors.surfaceVariant,
                AppColors.border,
                AppColors.surfaceVariant,
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShimmerLoading {
  ShimmerLoading._();

  static Widget card({double height = 140}) =>
      ShimmerBox(width: double.infinity, height: height);

  static Widget listItem({double height = 72}) =>
      ShimmerBox(width: double.infinity, height: height);

  static Widget statGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: ShimmerBox(height: 100)),
            const SizedBox(width: 12),
            Expanded(child: ShimmerBox(height: 100)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: ShimmerBox(height: 100)),
            const SizedBox(width: 12),
            Expanded(child: ShimmerBox(height: 100)),
          ],
        ),
      ],
    );
  }

  static Widget announcement() => ShimmerBox(height: 80);

  static Widget taskItem() => ShimmerBox(height: 72);
}
