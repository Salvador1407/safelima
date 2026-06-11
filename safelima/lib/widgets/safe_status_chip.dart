import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';

enum SafeStatusTone { success, warning, danger, info, neutral }

class SafeStatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final SafeStatusTone tone;

  const SafeStatusChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = SafeStatusTone.info,
  });

  const SafeStatusChip.success({super.key, required this.label, this.icon})
    : tone = SafeStatusTone.success;

  const SafeStatusChip.warning({super.key, required this.label, this.icon})
    : tone = SafeStatusTone.warning;

  const SafeStatusChip.danger({super.key, required this.label, this.icon})
    : tone = SafeStatusTone.danger;

  const SafeStatusChip.info({super.key, required this.label, this.icon})
    : tone = SafeStatusTone.info;

  const SafeStatusChip.neutral({super.key, required this.label, this.icon})
    : tone = SafeStatusTone.neutral;

  Color _color(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (tone) {
      case SafeStatusTone.success:
        return AppColors.success;
      case SafeStatusTone.warning:
        return AppColors.warning;
      case SafeStatusTone.danger:
        return AppColors.danger;
      case SafeStatusTone.info:
        return AppColors.info;
      case SafeStatusTone.neutral:
        return isDark ? AppColors.subtitleDark : AppColors.subtitleLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08), // Más sutil
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.26), // Fino borde de definición
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
