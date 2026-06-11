import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';

InputDecoration safeInputDecoration(
  BuildContext context, {
  required String labelText,
  String? hintText,
  IconData? prefixIcon,
  Widget? suffixIcon,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final subtitleColor = isDark
      ? AppColors.subtitleDark
      : AppColors.subtitleLight;
  final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
  final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
  final focusColor = isDark ? AppColors.secondaryDark : AppColors.primary;

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
    suffixIcon: suffixIcon,
    labelStyle: GoogleFonts.poppins(color: subtitleColor),
    hintStyle: GoogleFonts.poppins(color: subtitleColor),
    filled: true,
    fillColor: cardColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16), // Radio de 16px premium
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: focusColor, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
    ),
  );
}
