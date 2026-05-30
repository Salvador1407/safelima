import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/screens/alerts_screen.dart';
import 'package:safelima/screens/map_screen.dart';
import 'package:safelima/screens/profile_screen.dart';
import 'package:safelima/screens/report_screen.dart';
import 'package:safelima/screens/settings_screen.dart';
import 'package:safelima/screens/statistics_screen.dart';
import 'package:safelima/services/user_alert_service.dart';
import 'package:safelima/models/user_alert.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserAlertService _alertService = UserAlertService();

  Future<UserAlert?> getMostRecentAlert() async {
    try {
      final alerts = await _alertService.getAllAlerts();
      if (alerts.isEmpty) return null;

      alerts.sort(
        (a, b) => (b.fecha ?? DateTime(0)).compareTo(a.fecha ?? DateTime(0)),
      );
      return alerts.first;
    } catch (e) {
      debugPrint("❌ Error obteniendo alertas: $e");
      return null;
    }
  }

  Future<List<UserAlert>> getRecentAlerts({int limit = 2}) async {
    try {
      final alerts = await _alertService.getAllAlerts();

      alerts.sort(
        (a, b) => (b.fecha ?? DateTime(0)).compareTo(a.fecha ?? DateTime(0)),
      );

      return alerts.take(limit).toList();
    } catch (e) {
      debugPrint("❌ Error obteniendo alertas: $e");
      return [];
    }
  }

  Future<bool> _onWillPop() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;
    final dialogBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
        title: Text(
          "¿Deseas salir de SafeLima?",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        content: Text(
          "Tu sesión seguirá activa.",
          style: GoogleFonts.poppins(color: subtitleColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancelar",
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Salir",
              style: GoogleFonts.poppins(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      return true;
    }
    return false;
  }

  Color _backgroundColor(bool isDark) {
    return isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
  }

  Color _cardColor(bool isDark) {
    return isDark ? AppColors.cardDark : AppColors.cardLight;
  }

  Color _textColor(bool isDark) {
    return isDark ? AppColors.textDark : AppColors.textLight;
  }

  Color _subtitleColor(bool isDark) {
    return isDark ? AppColors.subtitleDark : AppColors.subtitleLight;
  }

  Color _borderColor(bool isDark) {
    return isDark ? AppColors.borderDark : AppColors.borderLight;
  }

  Color _mainButtonColor(String type, bool isDark) {
    if (isDark) {
      switch (type) {
        case 'map':
          return const Color(0xFF1F3B2D);
        case 'alert':
          return const Color(0xFF4A2C2A);
        case 'report':
          return const Color(0xFF223A4A);
        case 'stats':
          return const Color(0xFF3A2B4A);
        default:
          return AppColors.cardDark;
      }
    } else {
      switch (type) {
        case 'map':
          return const Color(0xFFD4EFDF);
        case 'alert':
          return const Color(0xFFFADBD8);
        case 'report':
          return const Color(0xFFD6EAF8);
        case 'stats':
          return const Color(0xFFE8DAEF);
        default:
          return AppColors.cardLight;
      }
    }
  }

  Color _alertCardBackground(bool isDark) {
    return isDark ? const Color(0xFF3A2323) : const Color(0xFFFFE5E5);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _backgroundColor(isDark);
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final borderColor = _borderColor(isDark);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            "SafeLima",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none,
                color: AppColors.white,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.person_outline, color: AppColors.white),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings, color: AppColors.white),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "¡Bienvenido!",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  "Mantente seguro en Lima",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 25),

                /// 🔹 Botones principales
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMainButton(
                      title: "Ver Mapa",
                      color: _mainButtonColor('map', isDark),
                      icon: Icons.map_outlined,
                      textColor: textColor,
                      borderColor: borderColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MapScreen()),
                        );
                      },
                    ),
                    _buildMainButton(
                      title: "Alertas",
                      color: _mainButtonColor('alert', isDark),
                      icon: Icons.warning_amber_outlined,
                      textColor: textColor,
                      borderColor: borderColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AlertsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMainButton(
                      title: "Reportar",
                      color: _mainButtonColor('report', isDark),
                      icon: Icons.add_circle_outline,
                      textColor: textColor,
                      borderColor: borderColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMainButton(
                      title: "Estadísticas",
                      color: _mainButtonColor('stats', isDark),
                      icon: Icons.bar_chart_outlined,
                      textColor: textColor,
                      borderColor: borderColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StatisticsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                /// 🔹 Últimas alertas registrada
                FutureBuilder<List<UserAlert>>(
                  future: getRecentAlerts(limit: 2),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Text(
                        "Error al cargar alertas: ${snapshot.error}",
                        style: GoogleFonts.poppins(color: AppColors.danger),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text(
                        "No hay alertas recientes",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                      );
                    }

                    final alerts = snapshot.data!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Alertas Recientes",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...alerts.map((alert) {
                          final dateStr = alert.fecha != null
                              ? DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(alert.fecha!.toLocal())
                              : "Sin fecha";

                          return _buildAlertCard(
                            title: alert.titulo,
                            subtitle:
                                "${alert.nivelRiesgo.toUpperCase()} - ${alert.grid?.nombre ?? 'Zona desconocida'} - $dateStr",
                            color: _alertCardBackground(isDark),
                            iconColor: AppColors.danger,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            borderColor: AppColors.danger.withOpacity(0.35),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton({
    required String title,
    required Color color,
    required IconData icon,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: textColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String subtitle,
    required Color color,
    required Color iconColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: iconColor, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
