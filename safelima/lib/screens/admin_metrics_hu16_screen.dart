import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/models/admin_metrics_model.dart';
import 'package:safelima/services/admin_metrics_service.dart';

class AdminMetricsHu16Screen extends StatefulWidget {
  const AdminMetricsHu16Screen({super.key});

  @override
  State<AdminMetricsHu16Screen> createState() => _AdminMetricsHu16ScreenState();
}

class _AdminMetricsHu16ScreenState extends State<AdminMetricsHu16Screen> {
  final AdminMetricsService _service = AdminMetricsService();

  AdminMetricsModel? _metrics;
  bool _loading = true;
  bool _metricsLoadFailed = false;

  static const String _metricsErrorMessage =
      "No se pudieron obtener las métricas";

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final connected = await _hasInternet();

    if (!mounted) return;

    if (!connected) {
      setState(() {
        _loading = false;
        _metricsLoadFailed = true;
      });

      _showMetricsError();
      return;
    }

    try {
      final data = await _service.getMetrics();

      if (!mounted) return;

      setState(() {
        _metrics = data;
        _loading = false;
        _metricsLoadFailed = false;
      });
    } on SocketException {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _metricsLoadFailed = true;
      });

      _showMetricsError();
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _metricsLoadFailed = true;
      });

      _showMetricsError();
    } catch (e) {
      debugPrint("Error técnico al cargar métricas: $e");

      if (!mounted) return;

      setState(() {
        _loading = false;
        _metricsLoadFailed = true;
      });

      _showMetricsError();
    }
  }

  Widget _buildMetricsErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: AppColors.danger, size: 48),
            const SizedBox(height: 14),
            Text(
              _metricsErrorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Verifica tu conexión o intenta nuevamente cuando el servidor esté disponible.",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _loading = true);
                _loadMetrics();
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                "Reintentar",
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
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

  void _showMetricsError() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(_metricsErrorMessage),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  int _getHighRiskTotal() {
    if (_metrics == null) return 0;
    final high = _metrics!.porNivelRiesgo.where(
      (e) => e.nivelRiesgo.toLowerCase() == 'alto',
    );
    if (high.isEmpty) return 0;
    return high.first.total;
  }

  String _formatMetricPercent(double? value) {
    if (value == null) return "--";
    return "${value.toStringAsFixed(2)}%";
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Sin fecha";
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildMetricRow(String label, int total, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              total.toString(),
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                color: color ?? AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopZonesList() {
    final zonas = _metrics!.porZona.take(5).toList();

    return _buildContainer(
      child: Column(
        children: zonas.map((z) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.12),
              child: const Icon(Icons.location_on, color: Colors.red),
            ),
            title: Text(
              z.gridNombre,
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
            subtitle: Text("Grid ID: ${z.gridId}"),
            trailing: Text(
              z.total.toString(),
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypeList() {
    return _buildContainer(
      child: Column(
        children: _metrics!.porTipoIncidente.map((e) {
          return _buildMetricRow(
            e.tipoIncidente,
            e.total,
            color: Colors.orange.shade700,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRiskList() {
    Color resolveColor(String riesgo) {
      switch (riesgo.toLowerCase()) {
        case 'alto':
          return Colors.red;
        case 'medio':
          return Colors.orange;
        case 'bajo':
          return Colors.green;
        default:
          return AppColors.primary;
      }
    }

    return _buildContainer(
      child: Column(
        children: _metrics!.porNivelRiesgo.map((e) {
          return _buildMetricRow(
            e.nivelRiesgo,
            e.total,
            color: resolveColor(e.nivelRiesgo),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusList() {
    return _buildContainer(
      child: Column(
        children: _metrics!.porEstado.map((e) {
          return _buildMetricRow(e.estado, e.total, color: AppColors.primary);
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineList() {
    final fechas = _metrics!.porFecha.take(7).toList();

    return _buildContainer(
      child: Column(
        children: fechas.map((e) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(
              e.fecha,
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
            trailing: Text(
              e.total.toString(),
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModelCard() {
    final modelo = _metrics!.modelo;

    return _buildContainer(
      child: modelo == null
          ? Text(
              "No hay métricas del modelo registradas.",
              style: GoogleFonts.manrope(fontSize: 14),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modelo.nombreModelo ?? "Modelo XGBoost",
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Versión: ${modelo.version ?? '--'}",
                  style: GoogleFonts.manrope(fontSize: 13),
                ),
                Text(
                  "Entrenado: ${_formatDate(modelo.fechaEntrenamiento)}",
                  style: GoogleFonts.manrope(fontSize: 13),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMiniMetric(
                      "Accuracy",
                      _formatMetricPercent(modelo.accuracy),
                    ),
                    _buildMiniMetric(
                      "Precision",
                      _formatMetricPercent(modelo.precision),
                    ),
                    _buildMiniMetric(
                      "Recall",
                      _formatMetricPercent(modelo.recall),
                    ),
                    _buildMiniMetric("F1", _formatMetricPercent(modelo.f1)),
                    _buildMiniMetric("AUC", _formatMetricPercent(modelo.auc)),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.manrope(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text("Metricas del Sistema"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _metrics == null && _metricsLoadFailed
          ? _buildMetricsErrorView()
          : _metrics == null
          ? const Center(child: Text("No hay métricas disponibles"))
          : RefreshIndicator(
              onRefresh: _loadMetrics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secundary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Cercado de Lima",
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Análisis de reportes y rendimiento del modelo predictivo",
                          style: GoogleFonts.manrope(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  _buildKpiCard(
                    title: "Total de reportes",
                    value: _metrics!.totalReportes.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: Colors.deepOrange,
                    subtitle: "Incidentes registrados en ${_metrics!.distrito}",
                  ),
                  const SizedBox(height: 12),

                  _buildKpiCard(
                    title: "Reportes de alto riesgo",
                    value: _getHighRiskTotal().toString(),
                    icon: Icons.priority_high_rounded,
                    color: Colors.red,
                    subtitle: "Clasificados con nivel de riesgo alto",
                  ),
                  const SizedBox(height: 12),

                  _buildKpiCard(
                    title: "Accuracy del modelo",
                    value: _formatMetricPercent(_metrics!.modelo?.accuracy),
                    icon: Icons.psychology_alt_rounded,
                    color: Colors.green,
                    subtitle: "Precisión global del modelo XGBoost",
                  ),
                  const SizedBox(height: 12),

                  _buildKpiCard(
                    title: "Precision del modelo",
                    value: _formatMetricPercent(_metrics!.modelo?.precision),
                    icon: Icons.analytics_rounded,
                    color: Colors.blue,
                    subtitle: "Calidad de predicciones positivas",
                  ),

                  _buildSectionTitle(
                    "Métricas del modelo",
                    Icons.memory_rounded,
                  ),
                  _buildModelCard(),

                  _buildSectionTitle(
                    "Reportes por estado",
                    Icons.rule_folder_outlined,
                  ),
                  _buildStatusList(),

                  _buildSectionTitle(
                    "Reportes por nivel de riesgo",
                    Icons.shield_outlined,
                  ),
                  _buildRiskList(),

                  _buildSectionTitle(
                    "Tipos de incidente",
                    Icons.crisis_alert_outlined,
                  ),
                  _buildTypeList(),

                  _buildSectionTitle(
                    "Zonas más críticas",
                    Icons.location_city_outlined,
                  ),
                  _buildTopZonesList(),

                  _buildSectionTitle(
                    "Evolución reciente",
                    Icons.show_chart_rounded,
                  ),
                  _buildTimelineList(),
                ],
              ),
            ),
    );
  }
}
