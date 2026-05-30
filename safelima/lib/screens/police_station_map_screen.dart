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

  @override
  Widget build(BuildContext context) {
    final position = LatLng(widget.station.latitud, widget.station.longitud);
    final markerId = MarkerId('police_${widget.station.id}');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.mainGradient),
        ),
        title: Text(
          widget.station.nombre,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: position, zoom: 16),
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
                  icon:
                      _stationMarkerIcon ??
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

          SafeCard(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.station.nombre,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Dirección: ${widget.station.direccion ?? 'Sin dirección'}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.subtitleDark
                              : AppColors.subtitleLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Teléfono: ${widget.station.telefono ?? 'Sin teléfono'}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.subtitleDark
                              : AppColors.subtitleLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.business_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Distrito: ${widget.station.distrito ?? 'No especificado'}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.subtitleDark
                              : AppColors.subtitleLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
