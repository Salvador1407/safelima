import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeNotifier() {
    _loadTheme();
  }

  // Cargar preferencia guardada
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  // Cambiar y guardar tema
  void toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = isDark;
    await prefs.setBool('dark_mode', isDark);
    notifyListeners();
  }
}
