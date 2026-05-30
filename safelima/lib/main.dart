import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/screens/inicio_screen.dart';
import 'package:safelima/services/app_notification_service.dart';
import 'package:safelima/theme/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppNotificationService.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafeLima',
      theme: _buildSafeLimaTheme(Brightness.light),
      darkTheme: _buildSafeLimaTheme(Brightness.dark),
      themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const InicioAppScreen(),
    );
  }
}

ThemeData _buildSafeLimaTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final primary = isDark ? AppColors.primaryDark : AppColors.primary;
  final secondary = isDark ? AppColors.secondaryDark : AppColors.secundary;
  final background = isDark
      ? AppColors.backgroundDark
      : AppColors.backgroundLight;
  final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
  final textColor = isDark ? AppColors.textDark : AppColors.textLight;
  final subtitleColor = isDark
      ? AppColors.subtitleDark
      : AppColors.subtitleLight;
  final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
  final baseTheme = ThemeData(brightness: brightness);
  final textTheme = GoogleFonts.poppinsTextTheme(
    baseTheme.textTheme,
  ).apply(bodyColor: textColor, displayColor: textColor);

  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: background,
    cardColor: cardColor,
    textTheme: textTheme,
    colorScheme: isDark
        ? ColorScheme.dark(primary: primary, secondary: secondary)
        : ColorScheme.light(primary: primary, secondary: secondary),
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: AppColors.white),
      titleTextStyle: GoogleFonts.poppins(
        color: AppColors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: AppColors.white,
        elevation: isDark ? 0 : 1,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        side: BorderSide(color: primary.withValues(alpha: 0.55)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      labelStyle: GoogleFonts.poppins(color: subtitleColor),
      hintStyle: GoogleFonts.poppins(color: subtitleColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
      ),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: isDark ? 0 : 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.info,
      contentTextStyle: GoogleFonts.poppins(
        color: AppColors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: GoogleFonts.poppins(
        color: textColor,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: GoogleFonts.poppins(color: subtitleColor, fontSize: 14),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
  );
}
