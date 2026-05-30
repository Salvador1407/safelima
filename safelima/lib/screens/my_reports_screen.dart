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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al cargar mis reportes: $e"),
          backgroundColor: AppColors.danger,
        ),
      );
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

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(_deleteReportErrorMessage),
        backgroundColor: AppColors.danger,
      ),
    );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reporte eliminado correctamente"),
          backgroundColor: AppColors.success,
        ),
      );

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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Eliminar reporte"),
          content: Text("¿Deseas eliminar el reporte \"${alert.titulo}\"?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
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

  Color _getStatusColor(String? estado) {
    switch ((estado ?? "").toLowerCase()) {
      case "recibido":
        return AppColors.info;
      case "en proceso":
        return AppColors.warning;
      case "cerrado":
        return AppColors.success;
      default:
        return Colors.grey;
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
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refreshMyReports,
              child: _myReports.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 120),
                        Icon(
                          Icons.assignment_late_outlined,
                          size: 64,
                          color: subtitleColor,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            "No tienes reportes registrados",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            "Cuando envíes reportes, aparecerán aquí.",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: subtitleColor,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _myReports.length,
                      itemBuilder: (context, index) {
                        final alert = _myReports[index];
                        final statusColor = _getStatusColor(alert.estado);

                        return Card(
                          color: cardColor,
                          elevation: isDark ? 1 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: borderColor),
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.assignment_outlined,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _getSafeText(alert.titulo),
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
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
                                        //height: 140,
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

                                const SizedBox(height: 10),

                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _getSafeText(
                                          alert.tipoIncidente,
                                          fallback: "Sin tipo",
                                        ),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _getSafeText(
                                          alert.estado,
                                          fallback: "Sin estado",
                                        ),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: statusColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                Text(
                                  "Fecha: ${_formatFecha(alert.fecha)}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    color: subtitleColor,
                                  ),
                                ),

                                if (alert.grid != null &&
                                    alert.grid!.nombre.isNotEmpty) ...[
                                  const SizedBox(height: 8),
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
                                    OutlinedButton.icon(
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
                                      icon: const Icon(Icons.edit_outlined),
                                      label: const Text("Editar"),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.danger,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => _confirmDelete(alert),
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text("Eliminar"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
