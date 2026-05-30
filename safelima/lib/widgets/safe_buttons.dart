import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';

enum SafeButtonVariant { primary, secondary, danger }

class SafeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final SafeButtonVariant variant;

  const SafeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.variant = SafeButtonVariant.primary,
  });

  const SafeButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = SafeButtonVariant.primary;

  const SafeButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = SafeButtonVariant.secondary;

  const SafeButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = SafeButtonVariant.danger;

  Color _backgroundColor(bool isDark) {
    switch (variant) {
      case SafeButtonVariant.secondary:
        return isDark ? AppColors.secondaryDark : AppColors.secundary;
      case SafeButtonVariant.danger:
        return AppColors.danger;
      case SafeButtonVariant.primary:
        return isDark ? AppColors.primaryDark : AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _backgroundColor(isDark);

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: AppColors.white,
      minimumSize: Size(fullWidth ? double.infinity : 0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      elevation: isDark ? 0 : 2,
      shadowColor: bgColor.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Curva suave premium (16px)
      ),
    );

    Widget childContent;
    if (isLoading) {
      childContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      );
    } else if (icon != null) {
      childContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      );
    } else {
      childContent = Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      );
    }

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: childContent,
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
