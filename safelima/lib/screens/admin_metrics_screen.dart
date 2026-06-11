import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/models/admin_metrics_model.dart';
import 'package:safelima/services/admin_metrics_service.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_shimmer.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';

class AdminMetricsScreen extends StatefulWidget {
  const AdminMetricsScreen({super.key});

  @override
  State<AdminMetricsScreen> createState() => _AdminMetricsScreenState();
}

class _AdminMetricsScreenState extends State<AdminMetricsScreen> {
  final AdminMetricsService _service = AdminMetricsService();
  AdminMetricsModel? _metrics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    try {
      final data = await _service.getMetrics();
      if (!mounted) return;
      setState(() {
        _metrics = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      SafeSnackBar.showError(context, "Error al cargar métricas: $e");
    }
  }

  Widget _buildCard(String title, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;

    return SafeCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 20),
      child: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSimpleList(List<Widget> children) {
    return SafeCard(
      padding: const EdgeInsets.all(14),
      child: Column(children: children),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SafeShimmer(width: double.infinity, height: 80),
        const SizedBox(height: 20),
        const SafeShimmer(width: 150, height: 24),
        const SizedBox(height: 10),
        SafeCard(
          child: Column(
            children: const [
              SafeShimmer(width: double.infinity, height: 40),
              SizedBox(height: 8),
              SafeShimmer(width: double.infinity, height: 40),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SafeShimmer(width: 150, height: 24),
        const SizedBox(height: 10),
        SafeCard(
          child: Column(
            children: const [
              SafeShimmer(width: double.infinity, height: 40),
              SizedBox(height: 8),
              SafeShimmer(width: double.infinity, height: 40),
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
    final Color subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Métricas de Reportes"),
        backgroundColor: isDark ? AppColors.cardDark : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? _buildLoadingShimmer()
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
                  _buildCard(
                    "Total de reportes",
                    _metrics!.totalReportes.toString(),
                    Icons.warning_amber_rounded,
                  ),

                  _buildSectionTitle("Por estado"),
                  _buildSimpleList(
                    _metrics!.porEstado.map((e) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          e.estado,
                          style: GoogleFonts.manrope(color: textColor),
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

                  _buildSectionTitle("Por nivel de riesgo"),
                  _buildSimpleList(
                    _metrics!.porNivelRiesgo.map((e) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          e.nivelRiesgo,
                          style: GoogleFonts.manrope(color: textColor),
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

                  _buildSectionTitle("Zonas críticas"),
                  _buildSimpleList(
                    _metrics!.porZona.take(5).map((e) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          e.gridNombre,
                          style: GoogleFonts.manrope(color: textColor),
                        ),
                        subtitle: Text(
                          "Grid ID: ${e.gridId}",
                          style: GoogleFonts.manrope(color: subtitleColor),
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

                  _buildSectionTitle("Evolución por fecha"),
                  _buildSimpleList(
                    _metrics!.porFecha.map((e) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          e.fecha,
                          style: GoogleFonts.manrope(color: textColor),
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
                ],
              ),
            ),
    );
  }
}
