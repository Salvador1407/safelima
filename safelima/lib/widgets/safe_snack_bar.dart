import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';

class SafeSnackBar {
  const SafeSnackBar._();

  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message,
      AppColors.success,
      Icons.check_circle_outline_rounded,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.danger, Icons.error_outline_rounded);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message, AppColors.warning, Icons.warning_amber_rounded);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppColors.info, Icons.info_outline_rounded);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: AppColors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
