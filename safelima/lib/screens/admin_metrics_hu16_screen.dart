import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/models/admin_metrics_model.dart';
import 'package:safelima/services/admin_metrics_service.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_shimmer.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';
import 'package:safelima/widgets/safe_buttons.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;

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
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Verifica tu conexión o intenta nuevamente cuando el servidor esté disponible.",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(fontSize: 13, color: subtitleColor),
            ),
            const SizedBox(height: 16),
            SafeButton(
              onPressed: () {
                setState(() => _loading = true);
                _loadMetrics();
              },
              icon: Icons.refresh,
              label: "Reintentar",
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
    SafeSnackBar.showError(context, _metricsErrorMessage);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;

    return SafeCard(
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
                    color: subtitleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: subtitleColor.withOpacity(0.8),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

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
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return SafeCard(padding: const EdgeInsets.all(14), child: child);
  }

  Widget _buildMetricRow(String label, int total, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

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
                color: textColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;

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
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            subtitle: Text(
              "Grid ID: ${z.gridId}",
              style: GoogleFonts.manrope(color: subtitleColor),
            ),
            trailing: Text(
              z.total.toString(),
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return _buildContainer(
      child: Column(
        children: fechas.map((e) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.calendar_today_outlined,
              color: isDark ? AppColors.secondaryDark : AppColors.primary,
            ),
            title: Text(
              e.fecha,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            trailing: Text(
              e.total.toString(),
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModelCard() {
    final modelo = _metrics!.modelo;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;

    return _buildContainer(
      child: modelo == null
          ? Text(
              "No hay métricas del modelo registradas.",
              style: GoogleFonts.manrope(fontSize: 14, color: textColor),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modelo.nombreModelo ?? "Modelo XGBoost",
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Versión: ${modelo.version ?? '--'}",
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
                Text(
                  "Entrenado: ${_formatDate(modelo.fechaEntrenamiento)}",
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;

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
            style: GoogleFonts.manrope(fontSize: 12, color: subtitleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SafeShimmer(width: double.infinity, height: 80),
        const SizedBox(height: 18),
        const SafeShimmer(width: double.infinity, height: 90),
        const SizedBox(height: 12),
        const SafeShimmer(width: double.infinity, height: 90),
        const SizedBox(height: 12),
        const SafeShimmer(width: double.infinity, height: 90),
        const SizedBox(height: 20),
        const SafeShimmer(width: 200, height: 24),
        const SizedBox(height: 10),
        SafeCard(
          child: Column(
            children: const [
              SafeShimmer(width: double.infinity, height: 20),
              SizedBox(height: 10),
              SafeShimmer(width: double.infinity, height: 16),
              SizedBox(height: 10),
              SafeShimmer(width: double.infinity, height: 16),
            ],
          ),
        ),
      ],
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
        title: const Text("Metricas del Sistema"),
        backgroundColor: isDark ? AppColors.cardDark : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? _buildLoadingShimmer()
          : _metrics == null && _metricsLoadFailed
          ? _buildMetricsErrorView()
          : _metrics == null
          ? Center(
              child: Text(
                "No hay métricas disponibles",
                style: GoogleFonts.manrope(fontSize: 15, color: textColor),
              ),
            )
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
