import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/models/admin_metrics_model.dart';
import 'package:safelima/services/admin_metrics_service.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al cargar métricas: $e")));
    }
  }

  Widget _buildCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                Text(title, style: GoogleFonts.manrope(fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 20),
      child: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSimpleList(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text("Métricas de Reportes"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _metrics == null
          ? const Center(child: Text("No hay métricas disponibles"))
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
                        title: Text(e.estado),
                        trailing: Text(
                          e.total.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),

                  _buildSectionTitle("Por nivel de riesgo"),
                  _buildSimpleList(
                    _metrics!.porNivelRiesgo.map((e) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.nivelRiesgo),
                        trailing: Text(
                          e.total.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),

                  _buildSectionTitle("Zonas críticas"),
                  _buildSimpleList(
                    _metrics!.porZona.take(5).map((e) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.gridNombre),
                        subtitle: Text("Grid ID: ${e.gridId}"),
                        trailing: Text(
                          e.total.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),

                  _buildSectionTitle("Evolución por fecha"),
                  _buildSimpleList(
                    _metrics!.porFecha.map((e) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.fecha),
                        trailing: Text(
                          e.total.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
