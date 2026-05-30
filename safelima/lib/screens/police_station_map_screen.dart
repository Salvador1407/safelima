import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safelima/models/policestations.dart';
import 'package:safelima/core/app_colors.dart';

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

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black12)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.station.nombre,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Dirección: ${widget.station.direccion ?? 'Sin dirección'}",
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "Teléfono: ${widget.station.telefono ?? 'Sin teléfono'}",
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "Distrito: ${widget.station.distrito ?? 'No especificado'}",
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
