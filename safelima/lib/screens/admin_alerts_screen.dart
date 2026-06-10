import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/models/user_alert.dart';
import 'package:safelima/services/user_alert_service.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_status_chip.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';
import 'package:safelima/widgets/safe_shimmer.dart';

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({super.key});

  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen> {
  final UserAlertService _alertService = UserAlertService();

  List<UserAlert> _alerts = [];
  bool _loading = true;
  static const String _updateStatusErrorMessage = "Error al actualizar estado";
  int _statusDropdownRefresh = 0;

  final List<String> _statusOptions = const [
    "Recibido",
    "En proceso",
    "Cerrado",
  ];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final alerts = await _alertService.getAllAlerts();

      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      SafeSnackBar.showError(context, "Error al cargar alertas: $e");
    }
  }

  Future<bool> _hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }

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

  void _showUpdateStatusError() {
    if (!mounted) return;
    SafeSnackBar.showError(context, _updateStatusErrorMessage);
  }

  Future<void> _changeStatus(UserAlert alert, String newStatus) async {
    final connected = await _hasInternet();

    if (!mounted) return;

    if (!connected) {
      setState(() {
        _statusDropdownRefresh++;
      });
      _showUpdateStatusError();
      return;
    }

    try {
      await _alertService.updateAlertStatus(
        alertId: alert.id!,
        estado: newStatus,
      );

      if (!mounted) return;

      setState(() {
        final index = _alerts.indexWhere((a) => a.id == alert.id);
        if (index != -1) {
          _alerts[index] = UserAlert(
            id: alert.id,
            titulo: alert.titulo,
            tipoIncidente: alert.tipoIncidente,
            descripcion: alert.descripcion,
            nivelRiesgo: alert.nivelRiesgo,
            rutaFoto: alert.rutaFoto,
            estado: newStatus,
            fecha: alert.fecha,
            grid: alert.grid,
          );
        }
      });

      SafeSnackBar.showSuccess(context, "Estado actualizado correctamente");
    } on SocketException {
      if (!mounted) return;
      setState(() {
        _statusDropdownRefresh++;
      });
      _showUpdateStatusError();
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _statusDropdownRefresh++;
      });
      _showUpdateStatusError();
    } catch (e) {
      debugPrint("Error técnico al actualizar estado: $e");

      if (!mounted) return;
      setState(() {
        _statusDropdownRefresh++;
      });
      _showUpdateStatusError();
    }
  }

  SafeStatusChip _buildRiskChip(String? riesgo) {
    final label = "Riesgo: ${riesgo ?? 'N/A'}";
    switch (riesgo?.toLowerCase()) {
      case 'alto':
        return SafeStatusChip.danger(
          label: label,
          icon: Icons.priority_high_rounded,
        );
      case 'medio':
        return SafeStatusChip.warning(
          label: label,
          icon: Icons.warning_amber_rounded,
        );
      case 'bajo':
        return SafeStatusChip.success(
          label: label,
          icon: Icons.check_circle_outline_rounded,
        );
      default:
        return SafeStatusChip.neutral(
          label: label,
          icon: Icons.help_outline_rounded,
        );
    }
  }

  SafeStatusChip _buildStatusChip(String? estado) {
    final label = "Estado: ${estado ?? 'N/A'}";
    switch (estado) {
      case 'Recibido':
        return SafeStatusChip.warning(
          label: label,
          icon: Icons.mark_email_unread_rounded,
        );
      case 'En proceso':
        return SafeStatusChip.info(label: label, icon: Icons.sync_rounded);
      case 'Cerrado':
        return SafeStatusChip.success(
          label: label,
          icon: Icons.task_alt_rounded,
        );
      default:
        return SafeStatusChip.neutral(
          label: label,
          icon: Icons.help_outline_rounded,
        );
    }
  }

  Widget _buildAlertCard(UserAlert alert) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;

    return SafeCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (alert.grid != null)
            Text(
              alert.grid!.nombre,
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

          const SizedBox(height: 8),

          Text(
            alert.tipoIncidente ?? "Sin tipo",
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            alert.descripcion,
            style: GoogleFonts.manrope(fontSize: 13.5, color: subtitleColor),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildRiskChip(alert.nivelRiesgo),
              _buildStatusChip(alert.estado),
            ],
          ),

          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: ValueKey(
              "status_${alert.id}_${alert.estado}_$_statusDropdownRefresh",
            ),
            initialValue: _statusOptions.contains(alert.estado)
                ? alert.estado
                : null,
            decoration: InputDecoration(
              labelText: "Cambiar estado",
              labelStyle: GoogleFonts.manrope(color: subtitleColor),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.secondaryDark : AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            style: GoogleFonts.manrope(color: textColor),
            dropdownColor: isDark ? AppColors.cardDark : AppColors.white,
            items: _statusOptions.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(
                  status,
                  style: GoogleFonts.manrope(color: textColor),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null && value != alert.estado) {
                _changeStatus(alert, value);
              }
            },
          ),

          if (alert.fecha != null) ...[
            const SizedBox(height: 10),
            Text(
              "Fecha: ${alert.fecha}",
              style: GoogleFonts.manrope(fontSize: 12.5, color: subtitleColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return SafeCard(
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SafeShimmer(width: 180, height: 20),
              const SizedBox(height: 10),
              const SafeShimmer(width: 120, height: 16),
              const SizedBox(height: 8),
              const SafeShimmer(width: double.infinity, height: 40),
              const SizedBox(height: 12),
              Row(
                children: const [
                  SafeShimmer(width: 90, height: 26, borderRadius: 20),
                  SizedBox(width: 10),
                  SafeShimmer(width: 90, height: 26, borderRadius: 20),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final Color textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Gestión de Reportes",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.cardDark : AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? _buildLoadingShimmer()
          : _alerts.isEmpty
          ? Center(
              child: Text(
                "No hay reportes registrados",
                style: GoogleFonts.manrope(fontSize: 15, color: textColor),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAlerts,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _alerts.length,
                itemBuilder: (context, index) {
                  return _buildAlertCard(_alerts[index]);
                },
              ),
            ),
    );
  }
}
