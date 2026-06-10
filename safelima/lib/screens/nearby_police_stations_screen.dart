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

  Color _backgroundColor(bool isDark) {
    return isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
  }

  Color _cardColor(bool isDark) {
    return isDark ? AppColors.cardDark : AppColors.cardLight;
  }

  Color _textColor(bool isDark) {
    return isDark ? AppColors.textDark : AppColors.textLight;
  }

  Color _subtitleColor(bool isDark) {
    return isDark ? AppColors.subtitleDark : AppColors.subtitleLight;
  }

  Color _borderColor(bool isDark) {
    return isDark ? AppColors.borderDark : AppColors.borderLight;
  }

  Color _accentColor(bool isDark) {
    return isDark ? AppColors.secondaryDark : AppColors.primary;
  }

  LinearGradient _appBarGradient(bool isDark) {
    return isDark
        ? const LinearGradient(
            colors: [
              AppColors.primaryDark,
              Color(0xFF102A43),
              AppColors.backgroundDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secundary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
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

  Widget _infoRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                height: 1.35,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
  }) {
    final accentColor = _accentColor(isDark);
    final cardColor = _cardColor(isDark);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.secundary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isDark ? cardColor : null,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? borderColor.withValues(alpha: 0.75)
              : AppColors.white.withValues(alpha: 0.34),
        ),
        boxShadow: _softShadow(isDark),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -44,
            right: -36,
            child: Container(
              width: 122,
              height: 122,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: isDark ? 0.04 : 0.10),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark
                      ? accentColor.withValues(alpha: 0.18)
                      : AppColors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? accentColor.withValues(alpha: 0.25)
                        : AppColors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: Icon(
                  Icons.local_police_rounded,
                  color: isDark ? accentColor : AppColors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${_stations.length} opciones próximas",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? textColor : AppColors.white,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Ordenadas según la cercanía a la zona seleccionada.",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.3,
                        color: isDark
                            ? subtitleColor
                            : AppColors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stationCard({
    required PoliceStation station,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDark,
  }) {
    final distance = _distanceKmTo(station).toStringAsFixed(2);
    final accentColor = _accentColor(isDark);
    final cardColor = _cardColor(isDark);

    return SafeCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      borderRadius: 22,
      backgroundColor: cardColor,
      borderColor: borderColor.withValues(alpha: isDark ? 0.55 : 0.85),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PoliceStationMapScreen(station: station),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              top: -36,
              right: -34,
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: isDark ? 0.10 : 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: isDark ? 0.22 : 0.15),
                          accentColor.withValues(alpha: isDark ? 0.10 : 0.07),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Icon(
                      Icons.local_police_rounded,
                      color: accentColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 13),
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                  height: 1.23,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SafeStatusChip.info(label: "$distance km"),
                          ],
                        ),
                        _infoRow(
                          icon: Icons.place_outlined,
                          text: station.direccion ?? "Sin dirección",
                          color: subtitleColor,
                        ),
                        _infoRow(
                          icon: Icons.phone_outlined,
                          text: station.telefono ?? "Sin teléfono",
                          color: subtitleColor,
                        ),
                        const SizedBox(height: 11),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(
                              alpha: isDark ? 0.14 : 0.09,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: accentColor.withValues(
                                alpha: isDark ? 0.22 : 0.16,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Ver ubicación",
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: accentColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      itemCount: 4,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: SafeShimmer(
          width: double.infinity,
          height: 148,
          borderRadius: 22,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: SafeEmptyState(
          icon: Icons.local_police_outlined,
          title: "No se encontraron comisarías",
          message: "Intenta consultar otra zona del mapa.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _backgroundColor(isDark);
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final borderColor = _borderColor(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.white,
        titleSpacing: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: _appBarGradient(isDark),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: isDark ? 0.30 : 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),
        title: Text(
          "Comisarías cercanas",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: _loading
          ? _buildLoadingList()
          : _stations.isEmpty
              ? _buildEmptyState()
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    _buildHeader(
                      isDark: isDark,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 18),
                    ..._stations.map(
                      (station) => _stationCard(
                        station: station,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
    );
  }
}