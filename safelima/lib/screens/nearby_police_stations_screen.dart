import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/models/policestations.dart';
import 'package:safelima/screens/police_station_map_screen.dart';
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
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudieron cargar las comisarías cercanas."),
          backgroundColor: AppColors.danger,
        ),
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

  List<BoxShadow> _softShadow(bool isDark) {
    return [
      BoxShadow(
        color: AppColors.black.withValues(alpha: isDark ? 0.24 : 0.08),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }

  Widget _buildEmptyState(
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: _softShadow(isDark),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_police_outlined,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "No se encontraron comisarías",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Intenta consultar otra zona del mapa.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.4,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
    required bool isDark,
  }) {
    final distance = _distanceKmTo(station).toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: _softShadow(isDark),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            "$distance km",
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _stations.isEmpty
          ? _buildEmptyState(cardColor, textColor, subtitleColor, isDark)
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
                    cardColor: cardColor,
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
