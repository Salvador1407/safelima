import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/core/app_data.dart';
import 'package:safelima/models/user_alert.dart';
import 'package:safelima/screens/edit_report_screen.dart';
import 'package:safelima/services/user_alert_service.dart';
import 'package:safelima/widgets/safe_buttons.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_dialog.dart';
import 'package:safelima/widgets/safe_empty_state.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';
import 'package:safelima/widgets/safe_shimmer.dart';
import 'package:safelima/widgets/safe_status_chip.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final UserAlertService _alertService = UserAlertService();

  List<UserAlert> _myReports = [];
  bool _loading = true;
  static const String _deleteReportErrorMessage = "Error al eliminar reporte";

  @override
  void initState() {
    super.initState();
    _loadMyReports();
  }

  Future<void> _loadMyReports() async {
    try {
      final reports = await _alertService.getAlertsByCitizen(
        AppData.citizen_id,
      );

      if (!mounted) return;

      setState(() {
        _myReports = reports;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      SafeSnackBar.showError(context, "Error al cargar mis reportes: $e");
    }
  }

  Future<void> _refreshMyReports() async {
    await _loadMyReports();
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
    } catch (_) {
      return false;
    }
  }

  void _showDeleteReportError() {
    if (!mounted) return;
    SafeSnackBar.showError(context, _deleteReportErrorMessage);
  }

  Future<void> _deleteReport(int id) async {
    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      _showDeleteReportError();
      return;
    }

    try {
      await _alertService.deleteAlert(id);

      if (!mounted) return;

      SafeSnackBar.showSuccess(context, "Reporte eliminado correctamente");

      await _loadMyReports();
    } catch (_) {
      if (!mounted) return;

      _showDeleteReportError();
    }
  }

  Future<void> _confirmDelete(UserAlert alert) async {
    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      _showDeleteReportError();
      return;
    }

    final confirm = await SafeDialog.showConfirmation(
      context,
      title: "Eliminar reporte",
      content: "¿Deseas eliminar el reporte \"${alert.titulo}\"?",
      confirmLabel: "Eliminar",
      cancelLabel: "Cancelar",
      icon: Icons.delete_forever_rounded,
      iconColor: AppColors.danger,
    );

    if (confirm == true) {
      await _deleteReport(alert.id!);
    }
  }

  String _formatFecha(DateTime? fecha) {
    if (fecha == null) return "Sin fecha";

    final day = fecha.day.toString().padLeft(2, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final year = fecha.year.toString();
    final hour = fecha.hour.toString().padLeft(2, '0');
    final minute = fecha.minute.toString().padLeft(2, '0');

    return "$day/$month/$year - $hour:$minute";
  }

  SafeStatusChip _buildStatusChip(String? estado) {
    switch ((estado ?? "").toLowerCase()) {
      case "recibido":
        return const SafeStatusChip.info(
          label: "RECIBIDO",
          icon: Icons.assignment_turned_in_outlined,
        );
      case "en proceso":
        return const SafeStatusChip.warning(
          label: "EN PROCESO",
          icon: Icons.run_circle_outlined,
        );
      case "cerrado":
        return const SafeStatusChip.success(
          label: "CERRADO",
          icon: Icons.check_circle_outline_rounded,
        );
      default:
        return const SafeStatusChip.neutral(
          label: "PENDIENTE",
          icon: Icons.hourglass_empty_rounded,
        );
    }
  }

  String _getSafeText(String? value, {String fallback = "Sin información"}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Mis reportes",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
      body: _loading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SafeShimmer(
                  width: double.infinity,
                  height: 180,
                  borderRadius: 18,
                ),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refreshMyReports,
              child: _myReports.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 80),
                        SafeEmptyState(
                          icon: Icons.assignment_late_outlined,
                          title: "No tienes reportes registrados",
                          message: "Cuando envíes reportes, aparecerán aquí.",
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _myReports.length,
                      itemBuilder: (context, index) {
                        final alert = _myReports[index];
                        final statusChip = _buildStatusChip(alert.estado);

                        return SafeCard(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.assignment_outlined,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _getSafeText(alert.titulo),
                                      style: GoogleFonts.poppins(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              Text(
                                _getSafeText(alert.descripcion),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: subtitleColor,
                                  height: 1.4,
                                ),
                              ),

                              if (alert.rutaFoto != null &&
                                  alert.rutaFoto!.isNotEmpty &&
                                  alert.rutaFoto!.startsWith('http'))
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      alert.rutaFoto!,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                height: 140,
                                                color: isDark
                                                    ? Colors.grey[800]
                                                    : Colors.grey[200],
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 12),

                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  SafeStatusChip.neutral(
                                    label: _getSafeText(
                                      alert.tipoIncidente,
                                      fallback: "Sin tipo",
                                    ).toUpperCase(),
                                    icon: Icons.label_outline_rounded,
                                  ),
                                  statusChip,
                                ],
                              ),

                              const SizedBox(height: 12),

                              Text(
                                "Fecha: ${_formatFecha(alert.fecha)}",
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  color: subtitleColor,
                                ),
                              ),

                              if (alert.grid != null &&
                                  alert.grid!.nombre.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "Zona: ${alert.grid!.nombre}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 14),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SafeButton.secondary(
                                    onPressed: () async {
                                      final updated = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              EditReportScreen(alert: alert),
                                        ),
                                      );

                                      if (updated == true) {
                                        await _loadMyReports();
                                      }
                                    },
                                    icon: Icons.edit_outlined,
                                    label: "Editar",
                                  ),
                                  const SizedBox(width: 10),
                                  SafeButton.danger(
                                    onPressed: () => _confirmDelete(alert),
                                    icon: Icons.delete_outline,
                                    label: "Eliminar",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
