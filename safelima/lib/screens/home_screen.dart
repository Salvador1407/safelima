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
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_dialog.dart';
import 'package:safelima/widgets/safe_shimmer.dart';

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
    final shouldExit = await SafeDialog.showConfirmation(
      context,
      title: "¿Deseas salir de SafeLima?",
      content: "Tu sesión seguirá activa.",
      confirmLabel: "Salir",
      cancelLabel: "Cancelar",
      icon: Icons.exit_to_app_rounded,
      iconColor: AppColors.danger,
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

  Color _textColor(bool isDark) {
    return isDark ? AppColors.textDark : AppColors.textLight;
  }

  Color _subtitleColor(bool isDark) {
    return isDark ? AppColors.subtitleDark : AppColors.subtitleLight;
  }

  Color _mainButtonColor(String type, bool isDark) {
    if (isDark) {
      switch (type) {
        case 'map':
          return const Color(0xFF1B3D2B);
        case 'alert':
          return const Color(0xFF4C2220);
        case 'report':
          return const Color(0xFF1E3547);
        case 'stats':
          return const Color(0xFF381F4C);
        default:
          return AppColors.cardDark;
      }
    } else {
      switch (type) {
        case 'map':
          return const Color(0xFFE8F8F5);
        case 'alert':
          return const Color(0xFFFCE4D6);
        case 'report':
          return const Color(0xFFEBF5FB);
        case 'stats':
          return const Color(0xFFF5EEF8);
        default:
          return AppColors.cardLight;
      }
    }
  }

  Color _alertCardBackground(bool isDark) {
    return isDark ? const Color(0xFF2C1C1C) : const Color(0xFFFFF2F2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _backgroundColor(isDark);
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Text(
            "SafeLima",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          flexibleSpace: isDark
              ? null
              : Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.mainGradient,
                  ),
                ),
          backgroundColor: isDark ? AppColors.backgroundDark : null,
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_rounded,
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
              icon: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.white,
              ),
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
              icon: const Icon(Icons.settings_rounded, color: AppColors.white),
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
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Mantente seguro en Lima",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                /// 🔹 Botones principales
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMainButton(
                      title: "Ver Mapa",
                      color: _mainButtonColor('map', isDark),
                      icon: Icons.map_outlined,
                      textColor: isDark
                          ? AppColors.success
                          : const Color(0xFF117A65),
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
                      textColor: isDark
                          ? AppColors.warning
                          : const Color(0xFFD35400),
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
                      icon: Icons.add_circle_outline_rounded,
                      textColor: isDark
                          ? AppColors.secondaryDark
                          : AppColors.primary,
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
                      textColor: isDark
                          ? const Color(0xFFBB8FCE)
                          : const Color(0xFF7D3C98),
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
                const SizedBox(height: 28),

                /// 🔹 Últimas alertas registradas
                FutureBuilder<List<UserAlert>>(
                  future: getRecentAlerts(limit: 2),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitlePlaceholder(isDark),
                          const SizedBox(height: 12),
                          const SafeShimmer.rectangular(
                            width: double.infinity,
                            height: 75,
                          ),
                          const SizedBox(height: 10),
                          const SafeShimmer.rectangular(
                            width: double.infinity,
                            height: 75,
                          ),
                        ],
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
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                            borderColor: AppColors.danger.withValues(
                              alpha: isDark ? 0.40 : 0.25,
                            ),
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

  Widget _buildTitlePlaceholder(bool isDark) {
    return const SafeShimmer.rectangular(width: 160, height: 22);
  }

  Widget _buildMainButton({
    required String title,
    required Color color,
    required IconData icon,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SafeCard(
      backgroundColor: color,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: textColor),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
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
    return SafeCard(
      backgroundColor: color,
      borderColor: borderColor,
      borderRadius: 16,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
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
