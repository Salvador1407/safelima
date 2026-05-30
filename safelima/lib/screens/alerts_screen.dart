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

  Color _textColor(bool isDark) {
    return isDark ? AppColors.textDark : AppColors.textLight;
  }

  Color _subtitleColor(bool isDark) {
    return isDark ? AppColors.subtitleDark : AppColors.subtitleLight;
  }

  Color _borderColor(bool isDark) {
    return isDark ? AppColors.borderDark : AppColors.borderLight;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _backgroundColor(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Alertas",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
      body: _loading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SafeShimmer(
                  width: double.infinity,
                  height: 160,
                  borderRadius: 18,
                ),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: isDark
                  ? AppColors.cardDark
                  : AppColors.cardLight,
              onRefresh: _refreshAlerts,
              child: _alerts.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 60),
                        SafeEmptyState(
                          icon: Icons.notifications_off_outlined,
                          title: "No hay alertas registradas",
                          message: "Desliza hacia abajo para actualizar.",
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildMyReportsAccess(isDark),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: _alerts.length,
                            itemBuilder: (context, index) {
                              final alert = _alerts[index];
                              return _buildAlertCard(alert, isDark);
                            },
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildMyReportsAccess(bool isDark) {
    return SafeCard(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.primary.withValues(alpha: 0.35),
      child: Row(
        children: [
          const Icon(Icons.assignment_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mis reportes",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Edita o elimina tus reportes.",
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: isDark
                        ? AppColors.subtitleDark
                        : AppColors.subtitleLight,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyReportsScreen()),
              );
            },
            child: const Text("Ver"),
          ),
        ],
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

    return SafeCard(
      margin: const EdgeInsets.only(bottom: 16),
      borderColor: statusColor.withValues(alpha: isDark ? 0.35 : 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              riskChip,
              Text(
                alert.fecha != null
                    ? "${alert.fecha!.hour}:${alert.fecha!.minute.toString().padLeft(2, '0')}"
                    : "--:--",
                style: GoogleFonts.poppins(color: subtitleColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),

          /// Título
          Text(
            alert.titulo,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),

          /// Descripción
          Text(
            alert.descripcion,
            style: GoogleFonts.poppins(fontSize: 13, color: subtitleColor),
          ),

          if (alert.rutaFoto != null &&
              alert.rutaFoto!.isNotEmpty &&
              alert.rutaFoto!.startsWith('http'))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  alert.rutaFoto!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),

          /// Ubicación
          if (alert.grid?.nombre != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? borderColor.withValues(alpha: 0.35)
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor.withValues(alpha: 0.7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      alert.grid!.nombre,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
