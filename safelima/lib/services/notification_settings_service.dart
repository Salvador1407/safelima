import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsService {
  static const String _keyNotificationsEnabled = 'notifications_enabled';

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, value);
  }
}
