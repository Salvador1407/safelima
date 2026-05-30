import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/models/policestations.dart';
import 'package:safelima/screens/police_station_map_screen.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_empty_state.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';
import 'package:safelima/widgets/safe_status_chip.dart';
import 'package:safelima/widgets/safe_shimmer.dart';

import '../services/police_station_service.dart';

class NearbyPoliceStationsScreen extends StatefulWidget {
  final double lat;
  final double lon;

  const NearbyPoliceStationsScreen({
    super.key,
    required this.lat,
    required this.lon,
  });

  @override
  State<NearbyPoliceStationsScreen> createState() =>
      _NearbyPoliceStationsScreenState();
}

class _NearbyPoliceStationsScreenState
    extends State<NearbyPoliceStationsScreen> {
  final PoliceStationService _service = PoliceStationService();
  bool _loading = true;
  List<PoliceStation> _stations = [];

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    try {
      final data = await _service.getNearby(
        lat: widget.lat,
        lon: widget.lon,
        limit: 5,
      );

      if (!mounted) return;

      final orderedStations = data.toList()
        ..sort((a, b) => _distanceKmTo(a).compareTo(_distanceKmTo(b)));

      setState(() {
        _stations = orderedStations.take(5).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
      SafeSnackBar.showError(
        context,
        "No se pudieron cargar las comisarías cercanas.",
      );
    }
  }

  double _distanceKmTo(PoliceStation station) {
    if (station.distanciaKm != null) return station.distanciaKm!;

    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(station.latitud - widget.lat);
    final dLon = _degreesToRadians(station.longitud - widget.lon);
    final lat1 = _degreesToRadians(widget.lat);
    final lat2 = _degreesToRadians(station.latitud);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 12.5, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stationCard({
    required PoliceStation station,
    required Color textColor,
    required Color subtitleColor,
    required bool isDark,
  }) {
    final distance = _distanceKmTo(station).toStringAsFixed(2);

    return SafeCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PoliceStationMapScreen(station: station),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.local_police, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          station.nombre,
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SafeStatusChip.info(label: "$distance km"),
                    ],
                  ),
                  _infoRow(
                    Icons.place_outlined,
                    station.direccion ?? "Sin dirección",
                    subtitleColor,
                  ),
                  _infoRow(
                    Icons.phone_outlined,
                    station.telefono ?? "Sin teléfono",
                    subtitleColor,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        "Ver ubicación",
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.secondaryDark
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: isDark
                            ? AppColors.secondaryDark
                            : AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.mainGradient),
        ),
        title: Text(
          "Comisarías cercanas",
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
                  height: 140,
                  borderRadius: 20,
                ),
              ),
            )
          : _stations.isEmpty
          ? const SafeEmptyState(
              icon: Icons.local_police_outlined,
              title: "No se encontraron comisarías",
              message: "Intenta consultar otra zona del mapa.",
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  "${_stations.length} opciones próximas",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Ordenadas según la cercanía a la zona seleccionada.",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 16),
                ..._stations.map(
                  (station) => _stationCard(
                    station: station,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
    );
  }
}
