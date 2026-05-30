import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/models/prediction_grid.dart';
import 'package:safelima/services/prediction_grid_service.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_empty_state.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';
import 'package:safelima/widgets/safe_status_chip.dart';
import 'package:safelima/widgets/safe_shimmer.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final PredictionGridService _predictionService = PredictionGridService();

  List<PredictionGrid> _predictions = [];
  bool _loading = true;
  static const String _statisticsLoadErrorMessage =
      "Error al cargar estadísticas";

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      _handleLoadFailure();
      return;
    }

    try {
      final data = await _predictionService.getAllPredictions();
      if (!mounted) return;

      setState(() {
        _predictions = data;
        _loading = false;
      });
    } on SocketException {
      _handleLoadFailure();
    } on TimeoutException {
      _handleLoadFailure();
    } catch (_) {
      _handleLoadFailure();
    }
  }

  void _handleLoadFailure() {
    if (!mounted) return;

    setState(() {
      _predictions = [];
      _loading = false;
    });

    _showStatisticsLoadError();
  }

  Future<void> _retryLoadPredictions() async {
    if (!mounted) return;

    setState(() => _loading = true);
    await _loadPredictions();
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
    } catch (_) {
      return false;
    }
  }

  void _showStatisticsLoadError() {
    if (!mounted) return;

    SafeSnackBar.showError(context, _statisticsLoadErrorMessage);
  }

  Color _bgColor(bool isDark) =>
      isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

  Color _textColor(bool isDark) =>
      isDark ? AppColors.textDark : AppColors.textLight;

  Color _subtitleColor(bool isDark) =>
      isDark ? AppColors.subtitleDark : AppColors.subtitleLight;

  Color _borderColor(bool isDark) =>
      isDark ? AppColors.borderDark : AppColors.borderLight;

  Color _riskColorFromAverage(double score) {
    if (score >= 2.5) return AppColors.danger;
    if (score >= 1.5) return AppColors.warning;
    return AppColors.success;
  }

  String _riskLabelFromAverage(double score) {
    if (score >= 2.5) return "ALTO";
    if (score >= 1.5) return "MEDIO";
    return "BAJO";
  }

  SafeStatusTone _riskToneFromLabel(String label) {
    switch (label) {
      case "ALTO":
        return SafeStatusTone.danger;
      case "MEDIO":
        return SafeStatusTone.warning;
      case "BAJO":
        return SafeStatusTone.success;
      default:
        return SafeStatusTone.neutral;
    }
  }

  IconData _riskIconFromTurn(String turn) {
    switch (turn) {
      case "Noche":
        return Icons.nightlight_round;
      case "Tarde":
        return Icons.wb_twilight_rounded;
      default:
        return Icons.wb_sunny_outlined;
    }
  }

  String _shortZoneLabel(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return "Zona";
    if (trimmed.length <= 12) return trimmed;

    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length == 1) return trimmed;

    final firstTwo = words.take(2).join(" ");
    return firstTwo.length <= 14 ? firstTwo : words.first;
  }

  List<Map<String, dynamic>> _buildZoneStats() {
    final Map<String, List<int>> grouped = {};

    for (final p in _predictions) {
      final zoneName = p.grid?.nombre ?? "Zona";
      grouped.putIfAbsent(zoneName, () => []).add(p.scoreRiesgo);
    }

    final result = grouped.entries.map((entry) {
      final scores = entry.value;
      final avg = scores.isEmpty
          ? 0.0
          : scores.reduce((a, b) => a + b) / scores.length;

      return {"nombre": entry.key, "riesgoPromedio": avg};
    }).toList();

    result.sort(
      (a, b) => (b["riesgoPromedio"] as double).compareTo(
        a["riesgoPromedio"] as double,
      ),
    );

    return result.take(7).toList();
  }

  List<Map<String, dynamic>> _buildTimeRiskStats() {
    final Map<String, Map<String, dynamic>> grouped = {
      "Mañana": {"rango": "06:00 - 11:59", "scores": <int>[]},
      "Tarde": {"rango": "12:00 - 17:59", "scores": <int>[]},
      "Noche": {"rango": "18:00 - 22:00", "scores": <int>[]},
    };

    for (final p in _predictions) {
      final date = p.fechaPrediccion;
      if (date == null) continue;

      final hour = date.hour;

      if (hour >= 6 && hour < 12) {
        (grouped["Mañana"]!["scores"] as List<int>).add(p.scoreRiesgo);
      } else if (hour >= 12 && hour < 18) {
        (grouped["Tarde"]!["scores"] as List<int>).add(p.scoreRiesgo);
      } else if (hour >= 18 && hour < 22) {
        (grouped["Noche"]!["scores"] as List<int>).add(p.scoreRiesgo);
      }
    }

    return grouped.entries.map((entry) {
      final values = entry.value["scores"] as List<int>;
      final hasData = values.isNotEmpty;
      final avg = hasData
          ? values.reduce((a, b) => a + b) / values.length
          : 0.0;

      return {
        "turno": entry.key,
        "rango": entry.value["rango"] as String,
        "label": hasData ? _riskLabelFromAverage(avg) : "Sin datos",
        "color": hasData ? _riskColorFromAverage(avg) : Colors.grey,
        "icon": _riskIconFromTurn(entry.key),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = _bgColor(isDark);
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final borderColor = _borderColor(isDark);

    final zonas = _buildZoneStats();
    final horarios = _buildTimeRiskStats();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Estadísticas",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        actions: const [
          Icon(Icons.bar_chart_rounded, color: AppColors.white),
          SizedBox(width: 12),
        ],
      ),
      body: _loading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SafeShimmer(
                  width: double.infinity,
                  height: 150,
                  borderRadius: 18,
                ),
              ),
            )
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadPredictions,
                color: AppColors.primary,
                child: _predictions.isEmpty
                    ? _buildEmptyState()
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(18),
                        children: [
                          _buildHeader(isDark: isDark),
                          const SizedBox(height: 18),
                          _buildDashboardCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                  title: "Criticidad por zona",
                                  icon: Icons.location_city_rounded,
                                  textColor: textColor,
                                ),
                                const SizedBox(height: 8),
                                _buildRiskLegend(),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 270,
                                  child: _buildZoneChart(
                                    zonas: zonas,
                                    subtitleColor: subtitleColor,
                                    borderColor: borderColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          _buildSectionTitle(
                            title: "Horarios de Mayor Riesgo",
                            icon: Icons.schedule_rounded,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 12),
                          ...horarios.map(
                            (item) => _buildRiskRow(
                              isDark: isDark,
                              turno: item["turno"] as String,
                              rango: item["rango"] as String,
                              label: item["label"] as String,
                              color: item["color"] as Color,
                              icon: item["icon"] as IconData,
                            ),
                          ),
                          const SizedBox(height: 25),
                        ],
                      ),
              ),
            ),
    );
  }

  Widget _buildHeader({required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.cardDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.mainGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Cercado de Lima",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Patrones de riesgo por zona y horario",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({required Widget child}) {
    return SizedBox(
      width: double.infinity,
      child: SafeCard(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required IconData icon,
    required Color textColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskLegend() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: const [
        _RiskLegendItem(label: "Alto", color: AppColors.danger),
        _RiskLegendItem(label: "Medio", color: AppColors.warning),
        _RiskLegendItem(label: "Bajo", color: AppColors.success),
      ],
    );
  }

  Widget _buildZoneChart({
    required List<Map<String, dynamic>> zonas,
    required Color subtitleColor,
    required Color borderColor,
  }) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 3.5,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: borderColor.withValues(alpha: 0.45),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= zonas.length) {
                  return const SizedBox();
                }

                final label = _shortZoneLabel(
                  zonas[index]["nombre"].toString(),
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: 58,
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: subtitleColor,
                        height: 1.1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: zonas.asMap().entries.map((entry) {
          final index = entry.key;
          final riesgoPromedio = entry.value["riesgoPromedio"] as double;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: riesgoPromedio,
                color: _riskColorFromAverage(riesgoPromedio),
                borderRadius: BorderRadius.circular(7),
                width: 20,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        SafeEmptyState(
          icon: Icons.bar_chart_outlined,
          title: "No hay datos estadísticos disponibles",
          message: "Intenta nuevamente cuando la conexión sea estable.",
          actionLabel: "Reintentar",
          onAction: _retryLoadPredictions,
        ),
      ],
    );
  }

  Widget _buildRiskRow({
    required bool isDark,
    required String turno,
    required String rango,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    final Color textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final Color subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;

    return SafeCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  turno,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rango,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          SafeStatusChip(label: label, tone: _riskToneFromLabel(label)),
        ],
      ),
    );
  }
}

class _RiskLegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _RiskLegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.subtitleDark : AppColors.subtitleLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
