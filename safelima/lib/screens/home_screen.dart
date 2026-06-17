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
import 'package:safelima/widgets/safe_status_chip.dart';

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

  Color _backgroundColor(bool isDark) =>
      isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

  Color _cardColor(bool isDark) =>
      isDark ? AppColors.cardDark : AppColors.cardLight;

  Color _textColor(bool isDark) =>
      isDark ? AppColors.textDark : AppColors.textLight;

  Color _subtitleColor(bool isDark) =>
      isDark ? AppColors.subtitleDark : AppColors.subtitleLight;

  Color _borderColor(bool isDark) =>
      isDark ? AppColors.borderDark : AppColors.borderLight;

  LinearGradient _heroGradient(bool isDark) {
    return isDark
        ? const LinearGradient(
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF102A43),
              Color(0xFF101820),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secundary,
              Color(0xFF7CCBFF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
  }

  Color _mainButtonAccent(String type, bool isDark) {
    switch (type) {
      case 'map':
        return isDark ? AppColors.success : const Color(0xFF117A65);
      case 'alert':
        return isDark ? AppColors.warning : const Color(0xFFD35400);
      case 'report':
        return isDark ? AppColors.secondaryDark : AppColors.primary;
      case 'stats':
        return isDark ? const Color(0xFFBB8FCE) : const Color(0xFF7D3C98);
      default:
        return isDark ? AppColors.secondaryDark : AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _backgroundColor(isDark);
    //final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(isDark),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      title: "Accesos Rápidos",
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.06,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMainButton(
                          title: "Ver Mapa",
                          subtitle: "Zonas de riesgo",
                          type: 'map',
                          icon: Icons.map_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MapScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMainButton(
                          title: "Alertas",
                          subtitle: "Reportes activos",
                          type: 'alert',
                          icon: Icons.warning_amber_rounded,
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
                          subtitle: "Nueva alerta",
                          type: 'report',
                          icon: Icons.add_circle_outline_rounded,
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
                          subtitle: "Datos de Lima",
                          type: 'stats',
                          icon: Icons.bar_chart_rounded,
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
                    FutureBuilder<List<UserAlert>>(
                      future: getRecentAlerts(limit: 2),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTitlePlaceholder(isDark),
                              const SizedBox(height: 12),
                              const SafeShimmer.rectangular(
                                width: double.infinity,
                                height: 92,
                                borderRadius: 22,
                              ),
                              const SizedBox(height: 10),
                              const SafeShimmer.rectangular(
                                width: double.infinity,
                                height: 92,
                                borderRadius: 22,
                              ),
                            ],
                          );
                        } else if (snapshot.hasError) {
                          return Text(
                            "Error al cargar alertas: ${snapshot.error}",
                            style: GoogleFonts.poppins(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Text(
                            "No hay alertas recientes",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: subtitleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }

                        final alerts = snapshot.data!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              title: "Alertas Recientes",
                              isDark: isDark,
                            ),
                            const SizedBox(height: 14),
                            ...alerts.map(
                              (alert) => _buildAlertCard(
                                alert: alert,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        22 + MediaQuery.of(context).padding.top,
        20,
        30,
      ),
      decoration: BoxDecoration(
        gradient: _heroGradient(isDark),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.black : AppColors.primary).withValues(
              alpha: isDark ? 0.36 : 0.22,
            ),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -38,
            right: -36,
            child: _buildDecorCircle(118, Colors.white.withValues(alpha: 0.10)),
          ),
          Positioned(
            bottom: -52,
            left: -34,
            child: _buildDecorCircle(96, Colors.white.withValues(alpha: 0.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildBrandMark(),
                  const SizedBox(width: 10),
                  Text(
                    "SafeLima",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                 // _buildHeroIconButton(
                 //   icon: Icons.notifications_none_rounded,
                 //   onPressed: () {},
                 // ),
                  const SizedBox(width: 9),
                  _buildHeroIconButton(
                    icon: Icons.person_outline_rounded,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 9),
                  _buildHeroIconButton(
                    icon: Icons.settings_rounded,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                "¡Bienvenido!",
                style: GoogleFonts.poppins(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                "Mantente seguro en Lima",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.86),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDecorCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildBrandMark() {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: const Icon(
        Icons.shield_outlined,
        color: Colors.white,
        size: 22,
      ),
    );
  }

  Widget _buildHeroIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.20),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
        splashRadius: 20,
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 21,
          decoration: BoxDecoration(
            color: isDark ? AppColors.secondaryDark : AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _textColor(isDark),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTitlePlaceholder(bool isDark) {
    return const SafeShimmer.rectangular(width: 170, height: 24);
  }

  Widget _buildMainButton({
    required String title,
    required String subtitle,
    required String type,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _mainButtonAccent(type, isDark);
    final cardColor = _cardColor(isDark);
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final borderColor = _borderColor(isDark);

    return SafeCard(
      backgroundColor: cardColor,
      padding: EdgeInsets.zero,
      onTap: onTap,
      borderColor: borderColor.withValues(alpha: isDark ? 0.55 : 0.85),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              top: -28,
              right: -28,
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: isDark ? 0.13 : 0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -34,
              left: -34,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: isDark ? 0.08 : 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: isDark ? 0.28 : 0.20),
                          accent.withValues(alpha: isDark ? 0.12 : 0.09),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: accent.withValues(alpha: isDark ? 0.24 : 0.18),
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 27,
                      color: accent,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: accent.withValues(alpha: 0.82),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required UserAlert alert,
    required bool isDark,
  }) {
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final cardColor = _cardColor(isDark);

    final dateStr = alert.fecha != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(alert.fecha!.toLocal())
        : "Sin fecha";

    Color riskColor;
    SafeStatusChip riskChip;

    switch (alert.nivelRiesgo.toLowerCase()) {
      case 'alto':
        riskColor = AppColors.danger;
        riskChip = const SafeStatusChip.danger(label: "Alto");
        break;
      case 'medio':
        riskColor = AppColors.warning;
        riskChip = const SafeStatusChip.warning(label: "Medio");
        break;
      case 'bajo':
        riskColor = AppColors.success;
        riskChip = const SafeStatusChip.success(label: "Bajo");
        break;
      default:
        riskColor = AppColors.info;
        riskChip = const SafeStatusChip.info(label: "Indefinido");
    }

    return SafeCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      backgroundColor: cardColor,
      borderColor: riskColor.withValues(alpha: isDark ? 0.32 : 0.18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      riskColor.withValues(alpha: isDark ? 0.10 : 0.07),
                      cardColor,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: isDark ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: riskColor.withValues(
                          alpha: isDark ? 0.25 : 0.18,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: riskColor,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alert.titulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 15.3,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            riskChip,
                          ],
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: subtitleColor,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                "${alert.grid?.nombre ?? 'Zona desconocida'} • $dateStr",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: subtitleColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}