import 'package:flutter/material.dart';
import 'package:safelima/core/app_colors.dart';

class SafeShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final ShapeBorder? shape;

  const SafeShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.shape,
  });

  const SafeShimmer.circular({super.key, required double size})
    : width = size,
      height = size,
      borderRadius = 999,
      shape = const CircleBorder();

  const SafeShimmer.rectangular({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  }) : shape = null;

  @override
  State<SafeShimmer> createState() => _SafeShimmerState();
}

class _SafeShimmerState extends State<SafeShimmer>
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark
        ? AppColors.borderDark.withValues(alpha: 0.5)
        : AppColors.borderLight.withValues(alpha: 0.75);
    final highlightColor = isDark
        ? AppColors.cardDark.withValues(alpha: 0.8)
        : AppColors.white.withValues(alpha: 0.95);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: ShapeDecoration(
            shape:
                widget.shape ??
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
            gradient: LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.35, 0.5, 0.65],
              begin: Alignment(-2.0 + 4.0 * _controller.value, -0.3),
              end: Alignment(-1.0 + 4.0 * _controller.value, 0.3),
            ),
          ),
        );
      },
    );
  }
}
