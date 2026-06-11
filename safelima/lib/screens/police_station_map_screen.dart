import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safelima/models/policestations.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/widgets/safe_card.dart';

class PoliceStationMapScreen extends StatefulWidget {
  final PoliceStation station;

  const PoliceStationMapScreen({super.key, required this.station});

  @override
  State<PoliceStationMapScreen> createState() => _PoliceStationMapScreenState();
}

class _PoliceStationMapScreenState extends State<PoliceStationMapScreen> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _stationMarkerIcon;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcon();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadMarkerIcon() async {
    try {
      final icon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/police_station_marker.png',
      );

      if (!mounted) return;

      setState(() => _stationMarkerIcon = icon);
    } catch (e) {
      debugPrint("Error cargando icono de comisaría: $e");
    }
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

  @override
  Widget build(BuildContext context) {
    final position = LatLng(widget.station.latitud, widget.station.longitud);
    final markerId = MarkerId('police_${widget.station.id}');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _backgroundColor(isDark),
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
          widget.station.nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: position,
                  zoom: 16,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _mapController?.showMarkerInfoWindow(markerId);
                  });
                },
                markers: {
                  Marker(
                    markerId: markerId,
                    position: position,
                    icon: _stationMarkerIcon ??
                        BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue,
                        ),
                    infoWindow: InfoWindow(
                      title: widget.station.nombre,
                      snippet: widget.station.direccion ?? "Sin dirección",
                    ),
                  ),
                },
              ),
            ),
          ),
          _buildStationInfoCard(isDark),
        ],
      ),
    );
  }

  Widget _buildStationInfoCard(bool isDark) {
    final cardColor = _cardColor(isDark);
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final borderColor = _borderColor(isDark);
    final accentColor = _accentColor(isDark);

    return SafeArea(
      top: false,
      child: SafeCard(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        padding: EdgeInsets.zero,
        backgroundColor: cardColor,
        borderColor: borderColor.withValues(alpha: isDark ? 0.55 : 0.85),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                top: -44,
                right: -38,
                child: Container(
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: isDark ? 0.10 : 0.07),
                  ),
                ),
              ),
              Positioned(
                bottom: -46,
                left: -40,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(
                      alpha: isDark ? 0.07 : 0.06,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor.withValues(
                                  alpha: isDark ? 0.24 : 0.16,
                                ),
                                accentColor.withValues(
                                  alpha: isDark ? 0.12 : 0.08,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Icon(
                            Icons.local_police_rounded,
                            color: accentColor,
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            widget.station.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildInfoBox(
                      isDark: isDark,
                      borderColor: borderColor,
                      children: [
                        _buildInfoRow(
                          icon: Icons.place_outlined,
                          label: "Dirección",
                          value: widget.station.direccion ?? 'Sin dirección',
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          icon: Icons.phone_outlined,
                          label: "Teléfono",
                          value: widget.station.telefono ?? 'Sin teléfono',
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          icon: Icons.business_outlined,
                          label: "Distrito",
                          value: widget.station.distrito ?? 'No especificado',
                          textColor: textColor,
                          subtitleColor: subtitleColor,
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

  Widget _buildInfoBox({
    required bool isDark,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withValues(alpha: 0.42)
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor.withValues(alpha: isDark ? 0.48 : 0.80),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final accentColor =
        Theme.of(context).brightness == Brightness.dark
            ? AppColors.secondaryDark
            : AppColors.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: accentColor,
        ),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: subtitleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.32,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}