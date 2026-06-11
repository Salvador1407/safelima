import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/screens/my_reports_screen.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_empty_state.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';
import 'package:safelima/widgets/safe_status_chip.dart';
import 'package:safelima/widgets/safe_shimmer.dart';
import '../../models/user_alert.dart';
import '../../services/user_alert_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final UserAlertService _alertService = UserAlertService();
  List<UserAlert> _alerts = [];
  bool _loading = true;
  static const String _loadAlertsErrorMessage = "Error al cargar alertas";

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      setState(() {
        _alerts = [];
        _loading = false;
      });
      _showLoadAlertsError();
      return;
    }

    try {
      final alerts = await _alertService.getAllAlerts();
      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _alerts = [];
        _loading = false;
      });
      _showLoadAlertsError();
    }
  }

  Future<bool> _hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return false;

    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  void _showLoadAlertsError() {
    if (!mounted) return;
    SafeSnackBar.showError(context, _loadAlertsErrorMessage);
  }

  Future<void> _refreshAlerts() async {
    await _loadAlerts();
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

  LinearGradient _appBarGradient(bool isDark) {
    return isDark
        ? const LinearGradient(
            colors: [
              AppColors.primaryDark,
              Color(0xFF102A43),
              AppColors.backgroundDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secundary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _backgroundColor(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.white,
        titleSpacing: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: _appBarGradient(isDark),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: isDark ? 0.30 : 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),
        title: Text(
          "Alertas",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: _loading
          ? _buildLoadingList(isDark)
          : RefreshIndicator(
              color: isDark ? AppColors.secondaryDark : AppColors.primary,
              backgroundColor: _cardColor(isDark),
              onRefresh: _refreshAlerts,
              child: _alerts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: _alerts.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildMyReportsAccess(isDark);
                        }

                        final alert = _alerts[index - 1];
                        return _buildAlertCard(alert, isDark);
                      },
                    ),
            ),
    );
  }

  Widget _buildLoadingList(bool isDark) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SafeShimmer(
          width: double.infinity,
          height: 164,
          borderRadius: 24,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 60),
        SafeEmptyState(
          icon: Icons.notifications_off_outlined,
          title: "No hay alertas registradas",
          message: "Desliza hacia abajo para actualizar.",
        ),
      ],
    );
  }

  Widget _buildMyReportsAccess(bool isDark) {
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final borderColor = _borderColor(isDark);
    final cardColor = _cardColor(isDark);
    final accentColor = isDark ? AppColors.secondaryDark : AppColors.primary;

    return SafeCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      backgroundColor: cardColor,
      borderColor: accentColor.withValues(alpha: isDark ? 0.34 : 0.22),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyReportsScreen()),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              top: -34,
              right: -30,
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: isDark ? 0.11 : 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: isDark ? 0.26 : 0.18),
                          accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: accentColor.withValues(
                          alpha: isDark ? 0.24 : 0.16,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.assignment_outlined,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Mis reportes",
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Edita o elimina tus reportes.",
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: isDark ? 0.15 : 0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: borderColor.withValues(alpha: isDark ? 0.45 : 0.7),
                      ),
                    ),
                    child: Text(
                      "Ver",
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
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

  Widget _buildAlertCard(UserAlert alert, bool isDark) {
    late Color statusColor;
    late SafeStatusChip riskChip;

    switch (alert.nivelRiesgo.toLowerCase()) {
      case "alto":
        statusColor = AppColors.danger;
        riskChip = const SafeStatusChip.danger(
          label: "ALTO RIESGO",
          icon: Icons.warning_amber_rounded,
        );
        break;
      case "medio":
        statusColor = AppColors.warning;
        riskChip = const SafeStatusChip.warning(
          label: "RIESGO MEDIO",
          icon: Icons.error_outline,
        );
        break;
      case "bajo":
        statusColor = AppColors.success;
        riskChip = const SafeStatusChip.success(
          label: "ZONA SEGURA",
          icon: Icons.verified_rounded,
        );
        break;
      default:
        statusColor = isDark ? AppColors.subtitleDark : Colors.grey;
        riskChip = const SafeStatusChip.neutral(
          label: "INDEFINIDO",
          icon: Icons.info_outline,
        );
    }

    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final borderColor = _borderColor(isDark);
    final cardColor = _cardColor(isDark);

    return SafeCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      backgroundColor: cardColor,
      borderColor: statusColor.withValues(alpha: isDark ? 0.34 : 0.20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withValues(alpha: isDark ? 0.11 : 0.07),
                      cardColor,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -42,
              right: -38,
              child: Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: isDark ? 0.10 : 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      riskChip,
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.black.withValues(alpha: 0.14)
                              : AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: borderColor.withValues(
                              alpha: isDark ? 0.50 : 0.75,
                            ),
                          ),
                        ),
                        child: Text(
                          alert.fecha != null
                              ? "${alert.fecha!.hour}:${alert.fecha!.minute.toString().padLeft(2, '0')}"
                              : "--:--",
                          style: GoogleFonts.poppins(
                            color: subtitleColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Text(
                    alert.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16.2,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    alert.descripcion,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.35,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (alert.rutaFoto != null &&
                      alert.rutaFoto!.isNotEmpty &&
                      alert.rutaFoto!.startsWith('http'))
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          children: [
                            Image.network(
                              alert.rutaFoto!,
                              width: double.infinity,
                              height: 158,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: subtitleColor,
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.black.withValues(alpha: 0.00),
                                      AppColors.black.withValues(alpha: 0.08),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (alert.grid?.nombre != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? borderColor.withValues(alpha: 0.30)
                            : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: borderColor.withValues(
                            alpha: isDark ? 0.45 : 0.75,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              alert.grid!.nombre,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}