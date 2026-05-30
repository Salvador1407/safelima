import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/core/app_data.dart';
import 'package:safelima/models/favorite_area.dart';
import 'package:safelima/models/grid.dart';
import 'package:safelima/models/prediction_grid.dart';
import 'package:safelima/models/safe_route_model.dart';
import 'package:safelima/screens/favorite_zones_screen.dart';
import 'package:safelima/screens/nearby_police_stations_screen.dart';
import 'package:safelima/services/favorite_area_service.dart';
import 'package:safelima/services/prediction_grid_service.dart';
import 'package:safelima/screens/zone_reviews_screen.dart';
import 'dart:math' as math;
import 'package:safelima/services/app_notification_service.dart';
import 'package:safelima/services/notification_settings_service.dart';
import 'package:safelima/models/policestations.dart';
import 'package:safelima/services/police_station_service.dart';
import 'package:safelima/services/safe_route_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  //Mapa
  final LatLng _center = const LatLng(-12.048142077983723, -77.03301695759941);
  GoogleMapController? _mapController;

  //Predicciones
  final PredictionGridService _predictionService = PredictionGridService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Set<Circle> _heatCircles = {};
  Set<Polyline> _routes = {};
  PredictionGrid? _selectedZone;

  List<PredictionGrid> _allZones = [];
  List<PredictionGrid> _filteredZones = [];

  bool _loading = true;
  bool _showSuggestions = false;
  bool _securityLayerUnavailable = false;

  static const String _securityLayerNoConnectionMessage =
      "No se pudo cargar la capa de seguridad por falta de conexión a internet";
  static const String _noInternetMessage = "No tienes conexión a internet";
  static const String _favoriteUpdateErrorMessage =
      "No se pudo actualizar favorito";
  static const String _safeRouteErrorMessage =
      "No se pudo calcular la ruta segura";
  static const String _noSearchResultsMessage =
      "No se encontraron zonas con ese nombre";

  //Ubicacion
  LocationData? _currentLocation;
  final Location _locationService = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  bool _locationReady = false;
  bool _locationDialogVisible = false;

  static const String _locationUnavailableMessage =
      "Para ofrecer una mejor experiencia, activa la ubicación del dispositivo.";

  //Lugares favoritos
  final FavoriteAreaService _favoriteService = FavoriteAreaService();
  Set<int> _favoriteGridIds = {};
  bool _favoritesLoading = false;

  //Notificaciones
  final NotificationSettingsService _notificationSettingsService =
      NotificationSettingsService();

  int? _lastDangerZoneAlertedId;
  DateTime? _lastDangerNotificationTime;

  static const double _dangerZoneRadiusMeters = 120.0;
  static const int _dangerNotificationCooldownMinutes = 5;
  Marker? _fakeLocationMarker;

  //Comisarias
  final PoliceStationService _policeStationService = PoliceStationService();

  List<PoliceStation> _allPoliceStations = [];
  List<PoliceStation> _nearbyPoliceStations = [];
  final Map<int, DateTime> _lastPoliceNotificationByStationId = {};
  bool _isPoliceStationTestMode = false;

  static const double _policeStationRadiusMeters = 120.0;
  static const int _policeNotificationCooldownMinutes = 5;

  BitmapDescriptor? _policeMarkerIcon;

  Set<Marker> _zoneMarkers = {};
  Set<Marker> _policeMarkers = {};

  //Camino mas seguro
  final SafeRouteService _safeRouteService = SafeRouteService();
  SafeRouteModel? _safeRouteResult;
  bool _isCalculatingRoute = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChange);
    _loadCustomMarkers();
    _initializeMap();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _searchFocusNode.removeListener(_handleSearchFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _closeZoneCard() {
    setState(() {
      _selectedZone = null;
      _showSuggestions = false;

      // opcional: también cerrar la ruta si estaba visible
      _safeRouteResult = null;
      _routes = {};
      _isCalculatingRoute = false;
    });
    _generateHeatCircles(_allZones);
  }

  Future<void> _initializeMap() async {
    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      setState(() {
        _allZones = [];
        _filteredZones = [];
        _heatCircles = {};
        _zoneMarkers = {};
        _policeMarkers = {};
        _selectedZone = null;
        _showSuggestions = false;
        _securityLayerUnavailable = true;
        _loading = false;
      });
      _showSecurityLayerConnectionMessage();
      _getUserLocation(loadRemoteData: false);
      return;
    }

    setState(() => _securityLayerUnavailable = false);
    _loadAllPoliceStations();
    _getUserLocation();
    _loadPredictions();
    _loadFavorites();
  }

  Future<bool> _hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return false;

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

  void _showSecurityLayerConnectionMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(_securityLayerNoConnectionMessage),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _showSafeRouteErrorMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(_safeRouteErrorMessage),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  Future<void> _requestSafeRoute(LatLng destination) async {
    if (_currentLocation?.latitude == null ||
        _currentLocation?.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo obtener tu ubicación actual."),
        ),
      );
      return;
    }

    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      _showSafeRouteErrorMessage();
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _safeRouteResult = null;
      _routes = {};
    });

    try {
      final result = await _safeRouteService.getSafeRoute(
        originLat: _currentLocation!.latitude!,
        originLon: _currentLocation!.longitude!,
        destinationLat: destination.latitude,
        destinationLon: destination.longitude,
      );

      final points = result.bestRoute.polyline
          .map((p) => LatLng(p.lat, p.lon))
          .toList();

      final routeColor = result.bestRoute.riskScore > 20
          ? AppColors.danger
          : result.bestRoute.riskScore > 10
          ? AppColors.warning
          : AppColors.primary;

      setState(() {
        _safeRouteResult = result;
        _routes = {
          Polyline(
            polylineId: const PolylineId("ruta_segura"),
            color: routeColor,
            width: 5,
            points: points,
          ),
        };
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Ruta segura encontrada. Riesgo: ${result.bestRoute.riskScore.toStringAsFixed(1)}",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Error calculando ruta segura: $e");
      _showSafeRouteErrorMessage();
    } finally {
      if (mounted) {
        setState(() {
          _isCalculatingRoute = false;
        });
      }
    }
  }

  void _clearSafeRoute() {
    setState(() {
      _safeRouteResult = null;
      _routes = {};
    });
  }

  Future<void> _loadCustomMarkers() async {
    try {
      final markerIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/police_station_marker.png',
      );

      if (!mounted) return;

      _policeMarkerIcon = markerIcon;

      if (_allPoliceStations.isNotEmpty) {
        _generatePoliceMarkers();
      }
    } catch (e) {
      debugPrint("Error cargando icono de comisaría: $e");
    }
  }

  Future<void> _loadAllPoliceStations() async {
    try {
      final stations = await _policeStationService.getAll();

      debugPrint("👮 Total comisarías recibidas: ${stations.length}");

      _allPoliceStations = stations;
      _generatePoliceMarkers();

      final currentLocation = _currentLocation;
      if (currentLocation != null) {
        await _checkNearbyPoliceStationNotification(currentLocation);
      }
    } catch (e) {
      debugPrint("Error cargando todas las comisarías: $e");
    }
  }

  Future<void> _loadNearbyPoliceStations({
    required double lat,
    required double lon,
  }) async {
    try {
      final stations = await _policeStationService.getNearby(
        lat: lat,
        lon: lon,
        limit: 5,
      );

      debugPrint("📍 Ubicación usuario: $lat, $lon");
      debugPrint("👮 Comisarías cercanas recibidas: ${stations.length}");

      for (final s in stations) {
        debugPrint("➡️ ${s.nombre} | ${s.latitud}, ${s.longitud}");
      }

      _nearbyPoliceStations = stations;
    } catch (e) {
      debugPrint("Error cargando comisarías cercanas: $e");
    }
  }

  Future<void> _updatePoliceStationProximity({
    required LocationData location,
    required LatLng userLatLng,
  }) async {
    final connected = await _hasInternet();
    if (!mounted || !connected) return;

    await _loadNearbyPoliceStations(
      lat: userLatLng.latitude,
      lon: userLatLng.longitude,
    );

    await _checkNearbyPoliceStationNotification(
      location,
      internetValidated: true,
    );
  }

  void _generatePoliceMarkers() {
    final policeMarkers = _allPoliceStations.map((station) {
      return Marker(
        markerId: MarkerId('police_${station.id}'),
        position: LatLng(station.latitud, station.longitud),
        icon:
            _policeMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: station.nombre,
          snippet:
              "${station.direccion ?? 'Sin dirección'}\nTel: ${station.telefono ?? 'Sin teléfono'}",
        ),
        onTap: () => _focusPoliceStation(station),
      );
    }).toSet();

    if (!mounted) return;

    setState(() {
      _policeMarkers = policeMarkers;
    });
  }

  void _focusPoliceStation(PoliceStation station) {
    final position = LatLng(station.latitud, station.longitud);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 16.5));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${station.nombre}\n${station.direccion ?? 'Sin dirección'}",
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _checkNearbyPoliceStationNotification(
    LocationData loc, {
    bool internetValidated = false,
  }) async {
    if (_isPoliceStationTestMode) return;

    if (!internetValidated) {
      final connected = await _hasInternet();
      if (!connected) return;
    }

    final notificationsEnabled = await _notificationSettingsService
        .getNotificationsEnabled();

    if (!notificationsEnabled) return;
    if (loc.latitude == null || loc.longitude == null) return;
    if (_allPoliceStations.isEmpty) return;

    PoliceStation? nearestStation;
    double nearestDistance = double.infinity;

    for (final station in _allPoliceStations) {
      final distance = _calculateDistanceMeters(
        loc.latitude!,
        loc.longitude!,
        station.latitud,
        station.longitud,
      );

      if (distance <= _policeStationRadiusMeters &&
          distance < nearestDistance) {
        nearestDistance = distance;
        nearestStation = station;
      }
    }

    if (nearestStation == null) return;

    final now = DateTime.now();

    final lastNotifiedAt =
        _lastPoliceNotificationByStationId[nearestStation.id];

    final sameStationRecentlyAlerted =
        lastNotifiedAt != null &&
        now.difference(lastNotifiedAt).inMinutes <
            _policeNotificationCooldownMinutes;

    if (sameStationRecentlyAlerted) return;

    final notificationPermissionGranted =
        await AppNotificationService.requestPermission();
    if (!notificationPermissionGranted) return;

    _lastPoliceNotificationByStationId[nearestStation.id] = now;

    try {
      await AppNotificationService.showPoliceStationNotification(
        stationName: nearestStation.nombre,
        district: nearestStation.distrito,
      );
    } catch (e) {
      debugPrint("Error mostrando notificación de comisaría: $e");
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '👮 Estás cerca de una comisaría: ${nearestStation.nombre}',
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _favoriteService.getFavoritesByCitizen(
        AppData.citizen_id,
      );
      print("id ciudadano: ${AppData.citizen_id}");
      if (!mounted) return;
      setState(() {
        _favoriteGridIds = favorites.map((f) => f.gridId).toSet();
      });
    } catch (e) {
      debugPrint("Error cargando favoritos: $e");
    }
  }

  double _calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  LatLng _generateNearbyPoint(double lat, double lon, double distanceMeters) {
    final random = math.Random();

    // dirección aleatoria (0 a 360 grados)
    final angle = random.nextDouble() * 2 * math.pi;

    // conversión metros → grados aproximados
    final deltaLat = (distanceMeters / 111320) * math.cos(angle);
    final deltaLon =
        (distanceMeters / (111320 * math.cos(lat * math.pi / 180))) *
        math.sin(angle);

    return LatLng(lat + deltaLat, lon + deltaLon);
  }

  Future<void> _checkDangerZoneNotification(LocationData loc) async {
    final connected = await _hasInternet();
    if (!connected) return;

    final notificationsEnabled = await _notificationSettingsService
        .getNotificationsEnabled();

    if (!notificationsEnabled) return;
    if (loc.latitude == null || loc.longitude == null) return;
    if (_allZones.isEmpty) return;

    PredictionGrid? nearestDangerZone;
    double nearestDistance = double.infinity;

    for (final zone in _allZones) {
      if (zone.grid?.centroLat == null || zone.grid?.centroLon == null) {
        continue;
      }

      final nivel = zone.nivelRiesgo.toLowerCase();
      if (nivel != 'alto' && nivel != 'medio') continue;

      final distance = _calculateDistanceMeters(
        loc.latitude!,
        loc.longitude!,
        zone.grid!.centroLat!,
        zone.grid!.centroLon!,
      );

      if (distance <= _dangerZoneRadiusMeters && distance < nearestDistance) {
        nearestDistance = distance;
        nearestDangerZone = zone;
      }
    }

    if (nearestDangerZone == null) return;

    final currentZoneId = nearestDangerZone.grid?.id;
    if (currentZoneId == null) return;

    final now = DateTime.now();

    final sameZoneRecentlyAlerted =
        _lastDangerZoneAlertedId == currentZoneId &&
        _lastDangerNotificationTime != null &&
        now.difference(_lastDangerNotificationTime!).inMinutes <
            _dangerNotificationCooldownMinutes;

    if (sameZoneRecentlyAlerted) return;

    _lastDangerZoneAlertedId = currentZoneId;
    _lastDangerNotificationTime = now;

    final nivel = nearestDangerZone.nivelRiesgo.toLowerCase();
    final isHigh = nivel == 'alto';

    await AppNotificationService.showDangerZoneNotification(
      zoneName: nearestDangerZone.grid?.nombre ?? 'Zona peligrosa',
      riskLevel: nearestDangerZone.nivelRiesgo,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isHigh
              ? '🚨 Estás cerca de una zona de riesgo ALTO: ${nearestDangerZone.grid?.nombre ?? "Zona"}'
              : '⚠️ Estás cerca de una zona de riesgo MEDIO: ${nearestDangerZone.grid?.nombre ?? "Zona"}',
        ),
        backgroundColor: isHigh ? AppColors.danger : AppColors.warning,
      ),
    );
  }

  void _goToFavoriteZone(FavoriteArea fav) {
    final favGridId = fav.gridId;

    final matchedZone = _allZones
        .where((z) => z.grid?.id == favGridId)
        .toList();

    if (matchedZone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo ubicar la zona favorita en el mapa."),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final zone = matchedZone.first;

    if (zone.grid?.centroLat == null || zone.grid?.centroLon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("La zona favorita no tiene coordenadas disponibles."),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _selectedZone = zone;
      _searchController.text = zone.grid?.nombre ?? '';
      _showSuggestions = false;
    });
    _generateHeatCircles(_allZones);

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(zone.grid!.centroLat!, zone.grid!.centroLon!),
        16,
      ),
    );
  }

  Future<void> _toggleFavoriteZone() async {
    if (_selectedZone?.grid?.id == null) return;

    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(_favoriteUpdateErrorMessage),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final gridId = _selectedZone!.grid!.id;
    final citizenId = AppData.citizen_id;

    setState(() => _favoritesLoading = true);

    try {
      final isFavorite = _favoriteGridIds.contains(gridId);

      if (isFavorite) {
        await _favoriteService.removeFavorite(citizenId, gridId);
        _favoriteGridIds.remove(gridId);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Zona eliminada de favoritos."),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        await _favoriteService.addFavorite(citizenId, gridId);
        _favoriteGridIds.add(gridId);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Zona agregada a favoritos."),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (!mounted) return;
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(_favoriteUpdateErrorMessage),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _favoritesLoading = false);
      }
    }
  }

  Future<void> _getUserLocation({bool loadRemoteData = true}) async {
    try {
      bool serviceEnabled = await _locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationService.requestService();
        if (!mounted) return;

        if (!serviceEnabled) {
          _setLocationUnavailable();
          return;
        }
      }

      PermissionStatus permission = await _locationService.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _locationService.requestPermission();
      }

      if (!mounted) return;

      if (permission != PermissionStatus.granted) {
        _setLocationUnavailable();
        return;
      }

      final location = await _locationService.getLocation();
      if (!mounted) return;

      final userLatLng = _latLngFromLocation(location);
      if (userLatLng == null) {
        _setLocationUnavailable();
        return;
      }

      setState(() {
        _currentLocation = location;
        _locationReady = true;
      });

      _centerCameraOn(userLatLng);

      if (loadRemoteData) {
        await _updatePoliceStationProximity(
          location: location,
          userLatLng: userLatLng,
        );

        await _checkDangerZoneNotification(location);
      }

      await _locationSubscription?.cancel();
      _locationSubscription = _locationService.onLocationChanged.listen((
        loc,
      ) async {
        if (!mounted) return;

        final locLatLng = _latLngFromLocation(loc);
        if (locLatLng == null) return;

        setState(() {
          _currentLocation = loc;
          _locationReady = true;
        });

        if (!loadRemoteData) return;

        await _updatePoliceStationProximity(
          location: loc,
          userLatLng: locLatLng,
        );

        await _checkDangerZoneNotification(loc);
      });
    } catch (e) {
      debugPrint("Error obteniendo ubicación actual: $e");
      if (!mounted) return;
      _setLocationUnavailable();
    }
  }

  LatLng? _latLngFromLocation(LocationData? location) {
    final lat = location?.latitude;
    final lon = location?.longitude;
    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }

  void _centerCameraOn(LatLng position, {double zoom = 16}) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, zoom));
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final userLatLng = _latLngFromLocation(_currentLocation);
    if (userLatLng != null) {
      _centerCameraOn(userLatLng);
    }
  }

  void _setLocationUnavailable() {
    if (!mounted) return;
    setState(() {
      _currentLocation = null;
      _locationReady = false;
    });
    _showLocationUnavailableDialog();
  }

  void _showLocationUnavailableDialog() {
    if (!mounted || _locationDialogVisible) return;

    _locationDialogVisible = true;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
        final textColor = isDark ? AppColors.textDark : AppColors.textLight;
        final subtitleColor = isDark
            ? AppColors.subtitleDark
            : AppColors.subtitleLight;

        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.location_off_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Ubicación desactivada",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            _locationUnavailableMessage,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.4,
              color: subtitleColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                "Entendido",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    ).whenComplete(() => _locationDialogVisible = false);
  }

  Future<void> _checkTestPoliceStationNotification({
    required LocationData loc,
    required PoliceStation testStation,
  }) async {
    final notificationsEnabled = await _notificationSettingsService
        .getNotificationsEnabled();

    if (!notificationsEnabled) return;
    if (loc.latitude == null || loc.longitude == null) return;

    final distance = _calculateDistanceMeters(
      loc.latitude!,
      loc.longitude!,
      testStation.latitud,
      testStation.longitud,
    );

    if (distance > _policeStationRadiusMeters) return;

    final notificationPermissionGranted =
        await AppNotificationService.requestPermission();

    if (!notificationPermissionGranted) return;

    _lastPoliceNotificationByStationId.remove(testStation.id);
    _lastPoliceNotificationByStationId[testStation.id] = DateTime.now();

    await AppNotificationService.showPoliceStationNotification(
      stationName: testStation.nombre,
      district: testStation.distrito,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('👮 Estás cerca de una comisaría: ${testStation.nombre}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _testPoliceStationNotificationNearCurrentLocation() async {
    LocationData? userLocation = _currentLocation;

    if (userLocation?.latitude == null || userLocation?.longitude == null) {
      try {
        userLocation = await _locationService.getLocation().timeout(
          const Duration(seconds: 2),
        );
      } catch (e) {
        debugPrint("Error obteniendo ubicación para prueba HU0011: $e");

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se pudo obtener tu ubicación actual."),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    }

    final userLatLng = _latLngFromLocation(userLocation);

    if (userLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo obtener tu ubicación actual."),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final testPoint = _generateNearbyPoint(
      userLatLng.latitude,
      userLatLng.longitude,
      60,
    );

    final testStation = PoliceStation(
      id: -999,
      nombre: "Comisaría de prueba HU0011",
      distrito: "Lima",
      direccion: "Ubicación generada cerca del usuario",
      telefono: "105",
      latitud: testPoint.latitude,
      longitud: testPoint.longitude,
    );

    final distance = _calculateDistanceMeters(
      userLatLng.latitude,
      userLatLng.longitude,
      testStation.latitud,
      testStation.longitud,
    );

    if (distance > _policeStationRadiusMeters) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "La comisaría de prueba quedó fuera del radio: ${distance.toStringAsFixed(1)} m.",
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final testMarker = Marker(
      markerId: const MarkerId("police_test_hu0011"),
      position: LatLng(testStation.latitud, testStation.longitud),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: testStation.nombre,
        snippet: "Prueba HU0011 - a ${distance.toStringAsFixed(1)} m",
      ),
    );

    setState(() {
      _currentLocation = userLocation;
      _locationReady = true;
      _selectedZone = null;
      _showSuggestions = false;

      _allPoliceStations.removeWhere((station) => station.id == -999);
      _allPoliceStations.add(testStation);

      _policeMarkers.removeWhere(
        (marker) => marker.markerId.value == "police_test_hu0011",
      );
      _policeMarkers = {..._policeMarkers, testMarker};
    });

    final notificationPermissionGranted =
        await AppNotificationService.requestPermission();

    if (!notificationPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se concedió permiso para mostrar notificaciones."),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    await AppNotificationService.showPoliceStationNotification(
      stationName: testStation.nombre,
      district: testStation.distrito,
    );

    _lastPoliceNotificationByStationId[testStation.id] = DateTime.now();

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 17));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "HU0011-1 OK: comisaría de prueba generada a ${distance.toStringAsFixed(1)} m de tu ubicación.",
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _injectTestDangerZoneNearCurrentLocation() async {
    if (_currentLocation?.latitude == null ||
        _currentLocation?.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo obtener tu ubicación actual."),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final testPoint = _generateNearbyPoint(
      _currentLocation!.latitude!,
      _currentLocation!.longitude!,
      60, // metros
    );

    final testZone = PredictionGrid(
      id: -999,
      gridId: -999,
      scoreRiesgo: 3,
      nivelRiesgo: "alto",
      fechaPrediccion: DateTime.now(),
      grid: Grid(
        id: -999,
        nombre: "Zona de prueba HU0014",
        centroLat: testPoint.latitude,
        centroLon: testPoint.longitude,
      ),
    );

    _allZones.removeWhere((z) => z.gridId == -999);
    _allZones.add(testZone);

    _generateHeatCircles(_allZones);

    _lastDangerZoneAlertedId = null;
    _lastDangerNotificationTime = null;

    setState(() {
      _selectedZone = testZone;
    });

    await _checkDangerZoneNotification(_currentLocation!);

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(testPoint.latitude, testPoint.longitude),
        17,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Zona de prueba agregada en ${testPoint.latitude.toStringAsFixed(6)}, ${testPoint.longitude.toStringAsFixed(6)}",
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _goToMyLocation() {
    final userLatLng = _latLngFromLocation(_currentLocation);

    if (userLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(_locationUnavailableMessage),
          backgroundColor: AppColors.warning,
        ),
      );
      _getUserLocation(loadRemoteData: !_securityLayerUnavailable);
      return;
    }

    setState(() {
      _fakeLocationMarker = null;
    });

    _centerCameraOn(userLatLng);
  }

  Future<void> _loadPredictions() async {
    try {
      final predictions = await _predictionService.getAllPredictions();
      _allZones = predictions;
      _securityLayerUnavailable = false;
      _generateHeatCircles(predictions);

      if (_currentLocation != null) {
        await _checkDangerZoneNotification(_currentLocation!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _allZones = [];
        _filteredZones = [];
        _heatCircles = {};
        _zoneMarkers = {};
        _selectedZone = null;
        _showSuggestions = false;
        _securityLayerUnavailable = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo cargar la capa de seguridad."),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _generateHeatCircles(List<PredictionGrid> predictions) {
    Set<Circle> circles = {};
    Set<Marker> markers = {};

    for (var p in predictions) {
      if (p.grid?.centroLat == null || p.grid?.centroLon == null) continue;

      final LatLng position = LatLng(p.grid!.centroLat!, p.grid!.centroLon!);
      final color = _getColor(p.nivelRiesgo);
      final isSelected = _isSelectedZone(p);

      circles.add(
        Circle(
          circleId: CircleId(p.grid?.nombre ?? "Zona"),
          center: position,
          radius: _getRadius(p.nivelRiesgo),
          fillColor: color.withValues(alpha: isSelected ? 0.6 : 0.35),
          strokeColor: isSelected ? color : Colors.transparent,
          strokeWidth: isSelected ? 3 : 0,
        ),
      );

      markers.add(
        Marker(
          markerId: MarkerId(p.grid?.nombre ?? "Zona"),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(_getHue(p.nivelRiesgo)),
          infoWindow: InfoWindow(title: p.grid?.nombre ?? "Zona sin nombre"),
          onTap: () => _selectZone(p),
        ),
      );
    }

    setState(() {
      _heatCircles = circles;
      _zoneMarkers = markers;
    });
  }

  bool _isSelectedZone(PredictionGrid zone) {
    final selectedGridId = _selectedZone?.grid?.id;
    if (selectedGridId != null && zone.grid?.id == selectedGridId) {
      return true;
    }

    final selectedPredictionId = _selectedZone?.id;
    return selectedPredictionId != null && zone.id == selectedPredictionId;
  }

  Color _getColor(String nivel) {
    switch (nivel.toLowerCase()) {
      case "bajo":
        return AppColors.success;
      case "medio":
        return AppColors.warning;
      case "alto":
        return AppColors.danger;
      default:
        return AppColors.info;
    }
  }

  double _getRadius(String nivel) => 100;

  double _getHue(String nivel) {
    switch (nivel.toLowerCase()) {
      case "bajo":
        return BitmapDescriptor.hueGreen;
      case "medio":
        return BitmapDescriptor.hueYellow;
      case "alto":
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

  String _formatRiskLevel(String nivel) {
    final normalized = nivel.trim().toLowerCase();
    if (normalized.isEmpty) return "Sin dato";
    return "${normalized[0].toUpperCase()}${normalized.substring(1)}";
  }

  List<BoxShadow> _softShadow(bool isDark) {
    return [
      BoxShadow(
        color: AppColors.black.withValues(alpha: isDark ? 0.24 : 0.10),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ];
  }

  Widget _riskChip(String nivel) {
    final color = _getColor(nivel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            nivel.toUpperCase(),
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoneMetricRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 8),
          Text(
            "$label:",
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 13, color: subtitleColor),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _mapActionStyle({
    required Color background,
    Color foreground = AppColors.white,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      elevation: 0,
      minimumSize: const Size(double.infinity, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  void _handleSearchFocusChange() {
    if (_searchFocusNode.hasFocus) {
      _hideZoneCardForSearch();
    }
  }

  void _hideZoneCardForSearch() {
    final hasVisibleZoneCard =
        _selectedZone != null ||
        _safeRouteResult != null ||
        _routes.isNotEmpty ||
        _isCalculatingRoute;

    if (!hasVisibleZoneCard) return;

    setState(() {
      _selectedZone = null;
      _safeRouteResult = null;
      _routes = {};
      _isCalculatingRoute = false;
    });

    if (_allZones.isNotEmpty) {
      _generateHeatCircles(_allZones);
    }
  }

  bool _hasValidZoneCoordinates(PredictionGrid zone) {
    return zone.grid?.centroLat != null && zone.grid?.centroLon != null;
  }

  String _normalizeSearchText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
  }

  void _showNoSearchResultsMessage() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(_noSearchResultsMessage),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  List<PredictionGrid> _findMatchingZones(String query) {
    final normalizedQuery = _normalizeSearchText(query);
    if (normalizedQuery.isEmpty) return [];

    final results = _allZones.where((zone) {
      if (!_hasValidZoneCoordinates(zone)) return false;
      final zoneName = _normalizeSearchText(zone.grid?.nombre ?? '');
      return zoneName.contains(normalizedQuery);
    }).toList();

    results.sort((a, b) {
      final aName = _normalizeSearchText(a.grid?.nombre ?? '');
      final bName = _normalizeSearchText(b.grid?.nombre ?? '');
      final aStarts = aName.startsWith(normalizedQuery);
      final bStarts = bName.startsWith(normalizedQuery);

      if (aStarts != bStarts) return aStarts ? -1 : 1;
      return aName.compareTo(bName);
    });

    return results;
  }

  void _clearSearch() {
    final hadText = _searchController.text.isNotEmpty;
    _searchController.clear();

    if (!hadText && !_showSuggestions && _filteredZones.isEmpty) return;

    setState(() {
      _filteredZones = [];
      _showSuggestions = false;
    });
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredZones = [];
        _showSuggestions = false;
      });
      return;
    }

    final results = _findMatchingZones(query);

    setState(() {
      _filteredZones = results;
      _showSuggestions = true;
    });
  }

  void _submitSearch(String query) {
    final normalizedQuery = _normalizeSearchText(query);
    if (normalizedQuery.isEmpty) {
      _clearSearch();
      return;
    }

    final exactMatches = _allZones
        .where(
          (zone) =>
              _hasValidZoneCoordinates(zone) &&
              _normalizeSearchText(zone.grid?.nombre ?? '') == normalizedQuery,
        )
        .toList();

    if (exactMatches.isNotEmpty) {
      _selectZone(exactMatches.first);
      return;
    }

    _hideZoneCardForSearch();

    setState(() {
      _filteredZones = [];
      _showSuggestions = false;
    });

    _showNoSearchResultsMessage();
  }

  void _selectZone(PredictionGrid zone) {
    if (!_hasValidZoneCoordinates(zone)) {
      _showNoSearchResultsMessage();
      return;
    }

    _searchFocusNode.unfocus();

    setState(() {
      _selectedZone = zone;
      _showSuggestions = false;
      _searchController.text = zone.grid?.nombre ?? '';
      _safeRouteResult = null;
      _routes = {};
    });
    _generateHeatCircles(_allZones);

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(zone.grid!.centroLat!, zone.grid!.centroLon!),
        16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final Color cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final Color textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final Color subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;
    final Color borderColor = isDark
        ? AppColors.borderDark
        : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.mainGradient),
        ),
        title: Text(
          "Mapa de Seguridad",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_police, color: Colors.white),
            tooltip: "Probar alerta por cercanía a comisaría",
            onPressed: _testPoliceStationNotificationNearCurrentLocation,
          ),
          IconButton(
            icon: const Icon(Icons.add_alert, color: Colors.white),
            tooltip: "Inyectar zona peligrosa cerca",
            onPressed: _injectTestDangerZoneNearCurrentLocation,
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.white),
            onPressed: () async {
              final connected = await _hasInternet();
              if (!context.mounted) return;

              if (!connected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(_noInternetMessage),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }

              final selectedFavorite = await Navigator.push<FavoriteArea>(
                context,
                MaterialPageRoute(builder: (_) => const FavoriteZonesScreen()),
              );
              if (!context.mounted) return;

              await _loadFavorites();
              if (!context.mounted) return;

              if (selectedFavorite != null) {
                _goToFavoriteZone(selectedFavorite);
              }
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _goToMyLocation,
        backgroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.my_location, color: AppColors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 15,
                  ),
                  myLocationEnabled: _locationReady,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  padding: EdgeInsets.only(
                    top: _securityLayerUnavailable ? 150 : 92,
                    bottom: _selectedZone != null ? 320 : 96,
                    left: 12,
                    right: 12,
                  ),
                  markers: {
                    ..._zoneMarkers,
                    ..._policeMarkers,
                    if (_fakeLocationMarker != null) _fakeLocationMarker!,
                  },
                  circles: _heatCircles,
                  polylines: _routes,
                  onMapCreated: _onMapCreated,
                  onTap: (_) => _closeZoneCard(),
                ),

                Positioned(
                  top: 15,
                  left: 15,
                  right: 15,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: borderColor.withValues(alpha: 0.8),
                          ),
                          boxShadow: _softShadow(isDark),
                        ),
                        child: TextField(
                          focusNode: _searchFocusNode,
                          controller: _searchController,
                          onTap: _hideZoneCardForSearch,
                          onChanged: _onSearchChanged,
                          onSubmitted: _submitSearch,
                          textInputAction: TextInputAction.search,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            height: 1.2,
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: "Buscar zona...",
                            hintStyle: GoogleFonts.poppins(
                              color: subtitleColor,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            prefixIcon: Icon(
                              Icons.search,
                              color: subtitleColor,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      color: subtitleColor,
                                    ),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),

                      if (_showSuggestions)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: borderColor.withValues(alpha: 0.8),
                            ),
                            boxShadow: _softShadow(isDark),
                          ),
                          child: _filteredZones.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.search_off,
                                        color: AppColors.warning,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _noSearchResultsMessage,
                                          style: GoogleFonts.poppins(
                                            color: textColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 240,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: _filteredZones.length,
                                    itemBuilder: (context, index) {
                                      final z = _filteredZones[index];
                                      return ListTile(
                                        title: Text(
                                          z.grid?.nombre ?? '',
                                          style: GoogleFonts.poppins(
                                            color: textColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          "Riesgo: ${z.nivelRiesgo.toUpperCase()}",
                                          style: GoogleFonts.poppins(
                                            color: subtitleColor,
                                            fontSize: 13,
                                          ),
                                        ),
                                        onTap: () => _selectZone(z),
                                      );
                                    },
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),

                if (_securityLayerUnavailable)
                  Positioned(
                    top: 86,
                    left: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.72),
                        ),
                        boxShadow: _softShadow(isDark),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off, color: AppColors.warning),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _securityLayerNoConnectionMessage,
                              style: GoogleFonts.poppins(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_selectedZone != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.fromLTRB(14, 14, 86, 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: borderColor.withValues(alpha: 0.85),
                        ),
                        boxShadow: _softShadow(isDark),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedZone!.grid?.nombre ??
                                      "Zona sin nombre",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18.5,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                              ),

                              _riskChip(_selectedZone!.nivelRiesgo),

                              IconButton(
                                onPressed: _closeZoneCard,
                                icon: Icon(Icons.close, color: subtitleColor),
                                tooltip: "Cerrar",
                                splashRadius: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: borderColor.withValues(alpha: 0.24),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                _zoneMetricRow(
                                  icon: Icons.security,
                                  label: "Nivel",
                                  value: _formatRiskLevel(
                                    _selectedZone!.nivelRiesgo,
                                  ),
                                  iconColor: _getColor(
                                    _selectedZone!.nivelRiesgo,
                                  ),
                                  textColor: textColor,
                                  subtitleColor: subtitleColor,
                                ),
                                _zoneMetricRow(
                                  icon: Icons.speed,
                                  label: "Riesgo",
                                  value: "${_selectedZone!.scoreRiesgo}/3",
                                  iconColor: AppColors.warning,
                                  textColor: textColor,
                                  subtitleColor: subtitleColor,
                                ),
                                _zoneMetricRow(
                                  icon: Icons.calendar_today_outlined,
                                  label: "Última predicción",
                                  value:
                                      _selectedZone!.fechaPrediccion
                                          ?.toLocal()
                                          .toString()
                                          .split(' ')
                                          .first ??
                                      "Sin fecha",
                                  iconColor: AppColors.info,
                                  textColor: textColor,
                                  subtitleColor: subtitleColor,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (_isCalculatingRoute) ...[
                            const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Calculando la ruta más segura...",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: subtitleColor,
                              ),
                            ),
                          ] else if (_safeRouteResult == null) ...[
                            ElevatedButton.icon(
                              onPressed: () => _requestSafeRoute(
                                LatLng(
                                  _selectedZone!.grid!.centroLat!,
                                  _selectedZone!.grid!.centroLon!,
                                ),
                              ),
                              icon: const Icon(Icons.route),
                              label: Text(
                                "Ruta Segura",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primary,
                                foregroundColor: AppColors.white,
                                elevation: 0,
                                minimumSize: const Size(double.infinity, 46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ZoneReviewsScreen(
                                      gridId: _selectedZone!.grid!.id,
                                      zoneName:
                                          _selectedZone!.grid!.nombre ?? "Zona",
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.reviews),
                              label: Text(
                                "Ver Reseñas",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                minimumSize: const Size(double.infinity, 46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NearbyPoliceStationsScreen(
                                      lat: _selectedZone!.grid!.centroLat!,
                                      lon: _selectedZone!.grid!.centroLon!,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.local_police),
                              label: Text(
                                "Comisarías cercanas",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: _mapActionStyle(
                                background: isDark
                                    ? AppColors.secondaryDark
                                    : AppColors.info,
                              ),
                            ),

                            const SizedBox(height: 10),

                            ElevatedButton.icon(
                              onPressed: _favoritesLoading
                                  ? null
                                  : _toggleFavoriteZone,
                              icon: Icon(
                                (_selectedZone?.grid?.id != null &&
                                        _favoriteGridIds.contains(
                                          _selectedZone!.grid!.id,
                                        ))
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                              ),
                              label: Text(
                                (_selectedZone?.grid?.id != null &&
                                        _favoriteGridIds.contains(
                                          _selectedZone!.grid!.id,
                                        ))
                                    ? "Quitar de favoritos"
                                    : "Agregar a favoritos",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(double.infinity, 46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ] else ...[
                            const Divider(),
                            const SizedBox(height: 6),

                            Builder(
                              builder: (_) {
                                final risk =
                                    _safeRouteResult!.bestRoute.riskScore;

                                Color riskColor;
                                if (risk > 20) {
                                  riskColor = AppColors.danger;
                                } else if (risk > 10) {
                                  riskColor = AppColors.warning;
                                } else {
                                  riskColor = AppColors.primary;
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "🛣️ Ruta sugerida",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: riskColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    Row(
                                      children: [
                                        const Icon(Icons.straighten, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Distancia:",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "${(_safeRouteResult!.bestRoute.distanceMeters / 1000).toStringAsFixed(2)} km",
                                          style: GoogleFonts.poppins(
                                            color: subtitleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Tiempo:",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "${(_safeRouteResult!.bestRoute.durationSeconds / 60).toStringAsFixed(0)} min",
                                          style: GoogleFonts.poppins(
                                            color: subtitleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.warning_amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Riesgo:",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _safeRouteResult!.bestRoute.riskScore
                                              .toStringAsFixed(1),
                                          style: GoogleFonts.poppins(
                                            color: riskColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Zonas peligrosas:",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "${_safeRouteResult!.bestRoute.dangerZonesCrossed}",
                                          style: GoogleFonts.poppins(
                                            color: riskColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.report_problem,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Zonas medias:",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "${_safeRouteResult!.bestRoute.mediumZonesCrossed}",
                                          style: GoogleFonts.poppins(
                                            color: AppColors.warning,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Zonas seguras:",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "${_safeRouteResult!.bestRoute.lowZonesCrossed}",
                                          style: GoogleFonts.poppins(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    ElevatedButton.icon(
                                      onPressed: _clearSafeRoute,
                                      icon: const Icon(Icons.close),
                                      label: Text(
                                        "Cerrar ruta",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.shade700,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(
                                          double.infinity,
                                          45,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
