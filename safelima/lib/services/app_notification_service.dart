import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    ); 

    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);
  }

  static Future<bool> requestPermission() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation == null) return true;

    final granted = await androidImplementation
        .requestNotificationsPermission();

    return granted ?? true;
  }

  static Future<void> showPoliceStationNotification({
    required String stationName,
    String? district,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'police_station_channel',
      'Alertas de Comisarías Cercanas',
      channelDescription: 'Alertas cuando el usuario se acerca a una comisaría',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
      ticker: 'Comisaría cercana',
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      2001,
      '👮 Comisaría cercana',
      district != null && district.isNotEmpty
          ? 'Estás cerca de $stationName, en $district.'
          : 'Estás cerca de $stationName.',
      details,
    );
  }

  static Future<void> showDangerZoneNotification({
    required String zoneName,
    required String riskLevel,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'danger_zone_channel',
      'Alertas de Zonas Peligrosas',
      channelDescription:
          'Alertas cuando el usuario se acerca a una zona peligrosa',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',

      // HU0018
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 300, 500]),

      ticker: 'Alerta de riesgo cercano',
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      1001,
      '⚠️ Zona peligrosa cercana',
      'Te estás acercando a $zoneName. Nivel de riesgo: ${riskLevel.toUpperCase()}.',
      details,
    );
  }

  static Future<void> showNow() async {
    final androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Canal de prueba SafeLima',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(0, '🚨 SafeLima', 'Notificaciones activadas', details);
  }
}
