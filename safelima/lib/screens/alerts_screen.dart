import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/screens/my_reports_screen.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(_loadAlertsErrorMessage),
        backgroundColor: AppColors.danger,
      ),
    );
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
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
                      children: [
                        const SizedBox(height: 120),
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: isDark
                              ? AppColors.subtitleDark
                              : AppColors.subtitleLight,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            "No hay alertas registradas",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textDark
                                  : AppColors.textLight,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            "Desliza hacia abajo para actualizar.",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.subtitleDark
                                  : AppColors.subtitleLight,
                            ),
                          ),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
      ),
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
    late IconData icon;
    late String label;

    switch (alert.nivelRiesgo.toLowerCase()) {
      case "alto":
        statusColor = AppColors.danger;
        icon = Icons.warning_amber_rounded;
        label = "ALTO RIESGO";
        break;
      case "medio":
        statusColor = AppColors.warning;
        icon = Icons.error_outline;
        label = "RIESGO MEDIO";
        break;
      case "bajo":
        statusColor = AppColors.success;
        icon = Icons.verified_rounded;
        label = "ZONA SEGURA";
        break;
      default:
        statusColor = isDark ? AppColors.subtitleDark : Colors.grey;
        icon = Icons.info_outline;
        label = "INDEFINIDO";
    }

    final cardColor = _cardColor(isDark);
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final borderColor = _borderColor(isDark);

    return Card(
      color: cardColor,
      elevation: isDark ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: statusColor.withOpacity(isDark ? 0.75 : 0.55),
          width: 1.5,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(icon, color: statusColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  alert.fecha != null
                      ? "${alert.fecha!.hour}:${alert.fecha!.minute.toString().padLeft(2, '0')}"
                      : "--:--",
                  style: GoogleFonts.poppins(
                    color: subtitleColor,
                    fontSize: 12,
                  ),
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

            // --- AQUÍ COLOCAS EL CÓDIGO DE LA IMAGEN ---
            if (alert.rutaFoto != null &&
                alert.rutaFoto!.isNotEmpty &&
                alert.rutaFoto!.startsWith(
                  'http',
                )) // Valida que sea una URL de internet
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    alert.rutaFoto!,
                    //height: 180,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? borderColor.withOpacity(0.35)
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor.withOpacity(0.7)),
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
      ),
    );
  }
}
