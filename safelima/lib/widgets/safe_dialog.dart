import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/widgets/safe_buttons.dart';

class SafeDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final IconData? icon;
  final Color? iconColor;

  const SafeDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.icon,
    this.iconColor,
  });

  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = "Confirmar",
    String cancelLabel = "Cancelar",
    IconData? icon = Icons.help_outline_rounded,
    Color? iconColor,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SafeDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }

  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String content,
    String buttonLabel = "Entendido",
    IconData? icon = Icons.info_outline_rounded,
    Color? iconColor,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => SafeDialog(
        title: title,
        content: content,
        confirmLabel: buttonLabel,
        onConfirm: () => Navigator.pop(context),
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final primaryColor = isDark ? AppColors.secondaryDark : AppColors.primary;
    final effectiveIconColor = iconColor ?? primaryColor;

    return Dialog(
      backgroundColor: cardColor,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: borderColor, width: 0.9),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: effectiveIconColor, size: 36),
              ),
              const SizedBox(height: 18),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.45,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (cancelLabel != null) ...[
                  TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.subtitleDark
                          : AppColors.subtitleLight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      cancelLabel!,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (confirmLabel != null)
                  SafeButton(
                    label: confirmLabel!,
                    onPressed: onConfirm,
                    icon: icon == Icons.help_outline_rounded
                        ? Icons.check_rounded
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
