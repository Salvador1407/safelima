import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safelima/screens/inicio_screen.dart';
import 'package:safelima/core/app_colors.dart';
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

      // 🌞 Tema Claro
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          iconTheme: IconThemeData(color: AppColors.white),
          titleTextStyle: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        cardColor: AppColors.cardLight,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textLight),
          bodyMedium: TextStyle(color: AppColors.textLight),
        ),
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secundary,
        ),
      ),

      // 🌙 Tema Oscuro
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryDark,
          iconTheme: IconThemeData(color: AppColors.white),
          titleTextStyle: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        cardColor: AppColors.cardDark,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textDark),
          bodyMedium: TextStyle(color: AppColors.textDark),
        ),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryDark,
          secondary: AppColors.secondaryDark,
        ),
      ),

      // 🌓 Activar tema dinámico
      themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      home: const InicioAppScreen(),
    );
  }
}
