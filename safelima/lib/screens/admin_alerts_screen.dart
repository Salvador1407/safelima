import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/models/user_alert.dart';
import 'package:safelima/services/user_alert_service.dart';

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
      // 1. Obtén la lista directamente (ya viene convertida por el service)
      final alerts = await _alertService.getAllAlerts();

      if (!mounted) return;
      setState(() {
        _alerts = alerts; // 2. Asigna la lista directamente
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al cargar alertas: $e"),
          backgroundColor: AppColors.danger,
        ),
      );
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(_updateStatusErrorMessage),
        backgroundColor: AppColors.danger,
      ),
    );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Estado actualizado correctamente"),
          backgroundColor: AppColors.success,
        ),
      );
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

  Color _statusColor(String? estado) {
    switch (estado) {
      case "Recibido":
        return Colors.orange;
      case "En proceso":
        return Colors.blue;
      case "Cerrado":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _riskColor(String? riesgo) {
    switch (riesgo?.toLowerCase()) {
      case "alto":
        return Colors.red;
      case "medio":
        return Colors.orange;
      case "bajo":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAlertCard(UserAlert alert) {
    final statusColor = _statusColor(alert.estado);
    final riskColor = _riskColor(alert.nivelRiesgo);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (alert.grid != null)
            Text(
              alert.grid!.nombre,
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

          const SizedBox(height: 8),

          Text(
            alert.tipoIncidente ?? "Sin tipo",
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            alert.descripcion ?? "Sin descripción",
            style: GoogleFonts.manrope(fontSize: 13.5, color: Colors.black54),
          ),

          const SizedBox(height: 12),

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
                  color: riskColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Riesgo: ${alert.nivelRiesgo ?? 'N/A'}",
                  style: GoogleFonts.manrope(
                    color: riskColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Estado: ${alert.estado ?? 'N/A'}",
                  style: GoogleFonts.manrope(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
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
              labelStyle: GoogleFonts.manrope(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: _statusOptions.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status, style: GoogleFonts.manrope()),
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
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(
          "Gestión de Reportes",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
          ? Center(
              child: Text(
                "No hay reportes registrados",
                style: GoogleFonts.manrope(fontSize: 15),
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
