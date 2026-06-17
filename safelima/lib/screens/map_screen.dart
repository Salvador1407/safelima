import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as app_permissions;
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
import 'package:safelima/services/connectivity_service.dart';
import 'package:safelima/services/notification_settings_service.dart';
import 'package:safelima/models/policestations.dart';
import 'package:safelima/services/police_station_service.dart';
import 'package:safelima/services/safe_route_service.dart';

enum _LocationUnavailableReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

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
  String? _selectedTramoHorario;

  bool _loading = true;
  bool _showSuggestions = false;
  bool _securityLayerUnavailable = false;
  bool _isConnected = true;
  bool _connectionLossNoticeShown = false;
  bool _handlingConnectivityChange = false;

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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _locationReady = false;
  bool _locationDialogVisible = false;

  static const String _locationUnavailableMessage =
      "SafeLima necesita permiso de ubicación para mostrar tu posición actual.";
  static const String _locationServiceDisabledMessage =
      "Para mostrar tu ubicación actual, activa la ubicación del dispositivo.";
  static const String _locationPermanentlyDeniedMessage =
      "El permiso de ubicación está bloqueado. Actívalo desde la configuración de la aplicación para mostrar tu posición actual.";

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
  final ConnectivityService _connectivityService = const ConnectivityService();
  SafeRouteModel? _safeRouteResult;
  bool _isCalculatingRoute = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChange);
    _loadCustomMarkers();
    _startConnectivityListener();
    _initializeMap();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _searchFocusNode.removeListener(_handleSearchFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _closeZoneCard({bool clearRoute = false}) {
    setState(() {
      _selectedZone = null;
      _showSuggestions = false;
      _isCalculatingRoute = false;

      if (clearRoute) {
        _safeRouteResult = null;
        _routes = {};
      }
    });

    _generateHeatCircles(_allZones);
  }

  Future<void> _initializeMap() async {
    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      final shouldNotify = !_connectionLossNoticeShown;

      setState(() {
        _isConnected = false;
        _connectionLossNoticeShown = true;
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
      if (shouldNotify) {
        _showSecurityLayerConnectionMessage();
      }
      _getUserLocation(loadRemoteData: false);
      return;
    }

    setState(() {
      _isConnected = true;
      _connectionLossNoticeShown = false;
      _securityLayerUnavailable = false;
    });
    _loadRemoteMapData();
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (_) => unawaited(_handleConnectivityChange()),
    );
  }

  Future<void> _handleConnectivityChange() async {
    if (_handlingConnectivityChange) return;

    _handlingConnectivityChange = true;
    try {
      final connected = await _hasInternet();
      if (!mounted) return;

      if (!connected) {
        final shouldNotify = _isConnected && !_connectionLossNoticeShown;

        setState(() {
          _isConnected = false;
          _connectionLossNoticeShown = true;
          _securityLayerUnavailable = true;
          _lastDangerZoneAlertedId = null;
          _lastDangerNotificationTime = null;

          if (_loading && _allZones.isEmpty) {
            _loading = false;
          }
        });

        if (shouldNotify) {
          _showSecurityLayerConnectionMessage();
        }

        return;
      }

      final recoveredFromOffline = !_isConnected;

      setState(() {
        _isConnected = true;
        _connectionLossNoticeShown = false;
        _securityLayerUnavailable = false;
      });

      if (recoveredFromOffline) {
        _loadRemoteMapData();
      }
    } finally {
      _handlingConnectivityChange = false;
    }
  }

  void _loadRemoteMapData() {
    _loadAllPoliceStations();
    _getUserLocation();
    _loadPredictions();
    _loadFavorites();
  }

  Future<bool> _hasInternet() async {
    return _connectivityService.hasInternet();
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
    if (!_isConnected) return;

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

  Future<void> _getUserLocation({
    bool loadRemoteData = true,
    bool centerCamera = false,
  }) async {
    try {
      bool serviceEnabled = await _locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationService.requestService();
        if (!mounted) return;

        if (!serviceEnabled) {
          _setLocationUnavailable(
            reason: _LocationUnavailableReason.serviceDisabled,
          );
          return;
        }
      }

      PermissionStatus permission = await _locationService.hasPermission();
      if (permission == PermissionStatus.deniedForever) {
        if (!mounted) return;
        _setLocationUnavailable(
          reason: _LocationUnavailableReason.permissionDeniedForever,
        );
        return;
      }

      if (permission == PermissionStatus.denied) {
        permission = await _locationService.requestPermission();
      }

      if (!mounted) return;

      if (permission == PermissionStatus.deniedForever) {
        _setLocationUnavailable(
          reason: _LocationUnavailableReason.permissionDeniedForever,
        );
        return;
      }

      if (!_isLocationPermissionGranted(permission)) {
        _setLocationUnavailable(
          reason: _LocationUnavailableReason.permissionDenied,
        );
        return;
      }

      final location = await _locationService.getLocation();
      if (!mounted) return;

      final userLatLng = _latLngFromLocation(location);
      if (userLatLng == null) {
        _setLocationUnavailable(
          reason: _LocationUnavailableReason.permissionDenied,
        );
        return;
      }

      setState(() {
        _currentLocation = location;
        _locationReady = true;
      });

      if (centerCamera) {
        _centerCameraOn(userLatLng);
      }

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
      _setLocationUnavailable(
        reason: _LocationUnavailableReason.permissionDenied,
      );
    }
  }

  bool _isLocationPermissionGranted(PermissionStatus permission) {
    return permission == PermissionStatus.granted ||
        permission == PermissionStatus.grantedLimited;
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
  }

  void _setLocationUnavailable({
    _LocationUnavailableReason reason =
        _LocationUnavailableReason.permissionDenied,
  }) {
    if (!mounted) return;
    setState(() {
      _currentLocation = null;
      _locationReady = false;
    });
    _showLocationUnavailableDialog(reason: reason);
  }

  void _showLocationUnavailableDialog({
    _LocationUnavailableReason reason =
        _LocationUnavailableReason.permissionDenied,
  }) {
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
        final isPermissionPermanentlyDenied =
            reason == _LocationUnavailableReason.permissionDeniedForever;
        final title = switch (reason) {
          _LocationUnavailableReason.serviceDisabled => "Ubicación desactivada",
          _LocationUnavailableReason.permissionDenied =>
            "Permiso de ubicación requerido",
          _LocationUnavailableReason.permissionDeniedForever =>
            "Permiso de ubicación bloqueado",
        };
        final message = switch (reason) {
          _LocationUnavailableReason.serviceDisabled =>
            _locationServiceDisabledMessage,
          _LocationUnavailableReason.permissionDenied =>
            _locationUnavailableMessage,
          _LocationUnavailableReason.permissionDeniedForever =>
            _locationPermanentlyDeniedMessage,
        };

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
                  title,
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
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.4,
              color: subtitleColor,
            ),
          ),
          actions: [
            if (isPermissionPermanentlyDenied)
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await app_permissions.openAppSettings();
                },
                child: Text(
                  "Abrir configuración",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
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
    final connected = await _hasInternet();
    if (!connected) return;

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
    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(_noInternetMessage),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

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
    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(_noInternetMessage),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

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
      _getUserLocation(
        loadRemoteData: !_securityLayerUnavailable,
        centerCamera: true,
      );
      return;
    }

    setState(() {
      _fakeLocationMarker = null;
    });

    _centerCameraOn(userLatLng);
  }

  Future<void> _loadPredictions() async {
    try {
      final predictions = await _predictionService.getCurrentPredictions();
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

  List<PredictionGrid> _getFilteredPredictions(
    List<PredictionGrid> predictions,
  ) {
    final Map<int, PredictionGrid> gridMostRecentPrediction = {};

    for (final p in predictions) {
      final gridId = p.grid?.id ?? p.gridId;
      if (gridId <= 0) continue;

      if (_selectedTramoHorario != null && p.tramoHorario != null) {
        if (p.tramoHorario != _selectedTramoHorario) {
          continue;
        }
      }

      final existing = gridMostRecentPrediction[gridId];
      if (existing == null) {
        gridMostRecentPrediction[gridId] = p;
      } else {
        final dateA = p.fechaPrediccion;
        final dateB = existing.fechaPrediccion;
        if (dateA != null && dateB != null) {
          if (dateA.isAfter(dateB)) {
            gridMostRecentPrediction[gridId] = p;
          }
        } else if (dateA != null) {
          gridMostRecentPrediction[gridId] = p;
        }
      }
    }

    return gridMostRecentPrediction.values.toList();
  }

  void _generateHeatCircles(List<PredictionGrid> predictions) {
    final filteredPredictions = _getFilteredPredictions(predictions);
    Set<Circle> circles = {};

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double opacityMultiplier = isDark ? 0.65 : 1.0;

    for (var p in filteredPredictions) {
      if (p.grid?.centroLat == null || p.grid?.centroLon == null) continue;

      final LatLng position = LatLng(p.grid!.centroLat!, p.grid!.centroLon!);
      final color = _getColor(p.nivelRiesgo);
      final isSelected = _isSelectedZone(p);
      final nivel = p.nivelRiesgo.toLowerCase();

      int zIndexVal = 1;
      if (nivel == 'alto') {
        zIndexVal = 3;
      } else if (nivel == 'medio') {
        zIndexVal = 2;
      }

      if (isSelected) {
        zIndexVal += 10;
      }

      Color coreColor = color;
      Color midColor = color;
      Color outColor = color;

      double coreRadius = 90;
      double midRadius = 135;
      double outRadius = 190;

      if (nivel == 'alto') {
        coreColor = AppColors.danger;
        midColor = AppColors.warning;
        outColor = AppColors.accent;
        coreRadius = 130;
        midRadius = 210;
        outRadius = 280;
      } else if (nivel == 'medio') {
        coreColor = AppColors.warning;
        midColor = AppColors.warning;
        outColor = AppColors.accent;
        coreRadius = 105;
        midRadius = 165;
        outRadius = 230;
      } else {
        coreColor = AppColors.success;
        midColor = AppColors.success;
        outColor = AppColors.success;
        coreRadius = 90;
        midRadius = 135;
        outRadius = 190;
      }

      final double coreOpacity = isSelected ? 0.45 : 0.38;
      final double midOpacity = isSelected ? 0.32 : 0.24;
      final double outOpacity = isSelected ? 0.22 : 0.15;

      final double currentCoreOpacity = coreOpacity * opacityMultiplier;
      final double currentMidOpacity = midOpacity * opacityMultiplier;
      final double currentOutOpacity = outOpacity * opacityMultiplier;

      circles.add(
        Circle(
          circleId: CircleId("circle_core_${p.grid?.id ?? p.gridId}"),
          center: position,
          radius: coreRadius,
          fillColor: coreColor.withValues(alpha: currentCoreOpacity),
          strokeColor: isSelected ? color : Colors.transparent,
          strokeWidth: isSelected ? 2 : 0,
          zIndex: zIndexVal,
          consumeTapEvents: true,
          onTap: () => _selectZone(p),
        ),
      );

      circles.add(
        Circle(
          circleId: CircleId("circle_mid_${p.grid?.id ?? p.gridId}"),
          center: position,
          radius: midRadius,
          fillColor: midColor.withValues(alpha: currentMidOpacity),
          strokeColor: Colors.transparent,
          strokeWidth: 0,
          zIndex: zIndexVal - 1,
          consumeTapEvents: true,
          onTap: () => _selectZone(p),
        ),
      );

      circles.add(
        Circle(
          circleId: CircleId("circle_out_${p.grid?.id ?? p.gridId}"),
          center: position,
          radius: outRadius,
          fillColor: outColor.withValues(alpha: currentOutOpacity),
          strokeColor: Colors.transparent,
          strokeWidth: 0,
          zIndex: zIndexVal - 2,
          consumeTapEvents: true,
          onTap: () => _selectZone(p),
        ),
      );
    }

    setState(() {
      _heatCircles = circles;
      _zoneMarkers = {};
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

  Color _subtitleColor(bool isDark) {
    return isDark ? AppColors.subtitleDark : AppColors.subtitleLight;
  }

  Color _borderColor(bool isDark) {
    return isDark ? AppColors.borderDark : AppColors.borderLight;
  }

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

    final filtered = _getFilteredPredictions(_allZones);
    final results = filtered.where((zone) {
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

    final filtered = _getFilteredPredictions(_allZones);
    final exactMatches = filtered
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

  Widget _mapActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    required bool isDark,
    bool filled = false,
    Color? foregroundColor,
  }) {
    final disabled = onPressed == null;

    final bgColor = disabled
        ? _borderColor(isDark).withValues(alpha: isDark ? 0.22 : 0.45)
        : filled
        ? color
        : color.withValues(alpha: isDark ? 0.16 : 0.10);

    final fgColor = disabled
        ? _subtitleColor(isDark)
        : foregroundColor ?? (filled ? AppColors.white : color);

    return SizedBox(
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(17),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: disabled
                    ? _borderColor(isDark).withValues(alpha: 0.55)
                    : color.withValues(alpha: filled ? 0.0 : 0.24),
              ),
              boxShadow: filled && !disabled
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: isDark ? 0.24 : 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 7),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: fgColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13.2,
                      fontWeight: FontWeight.w800,
                      color: fgColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _appBarActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: AppColors.white.withValues(alpha: 0.14),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(icon, color: AppColors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _routeInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color textColor,
    required Color subtitleColor,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: _borderColor(isDark).withValues(alpha: isDark ? 0.24 : 0.36),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _borderColor(isDark).withValues(alpha: isDark ? 0.34 : 0.55),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 8),
          Text(
            "$label:",
            style: GoogleFonts.poppins(
              fontSize: 12.4,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12.4,
                fontWeight: FontWeight.w600,
                color: subtitleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeRouteResult({
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final risk = _safeRouteResult!.bestRoute.riskScore;

    Color riskColor;
    if (risk > 20) {
      riskColor = AppColors.danger;
    } else if (risk > 10) {
      riskColor = AppColors.warning;
    } else {
      riskColor = isDark ? AppColors.secondaryDark : AppColors.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          color: _borderColor(isDark).withValues(alpha: isDark ? 0.45 : 0.70),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.alt_route_rounded, color: riskColor, size: 22),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                "Ruta sugerida",
                style: GoogleFonts.poppins(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            _riskChip(
              risk > 20
                  ? "alto"
                  : risk > 10
                  ? "medio"
                  : "bajo",
            ),
          ],
        ),
        const SizedBox(height: 13),
        _routeInfoRow(
          icon: Icons.straighten_rounded,
          label: "Distancia",
          value:
              "${(_safeRouteResult!.bestRoute.distanceMeters / 1000).toStringAsFixed(2)} km",
          iconColor: AppColors.info,
          textColor: textColor,
          subtitleColor: subtitleColor,
          isDark: isDark,
        ),
        _routeInfoRow(
          icon: Icons.access_time_rounded,
          label: "Tiempo",
          value:
              "${(_safeRouteResult!.bestRoute.durationSeconds / 60).toStringAsFixed(0)} min",
          iconColor: AppColors.warning,
          textColor: textColor,
          subtitleColor: subtitleColor,
          isDark: isDark,
        ),
        _routeInfoRow(
          icon: Icons.warning_amber_rounded,
          label: "Riesgo",
          value: _safeRouteResult!.bestRoute.riskScore.toStringAsFixed(1),
          iconColor: riskColor,
          textColor: textColor,
          subtitleColor: subtitleColor,
          isDark: isDark,
        ),
        _routeInfoRow(
          icon: Icons.report_problem_rounded,
          label: "Zonas peligrosas",
          value: "${_safeRouteResult!.bestRoute.dangerZonesCrossed}",
          iconColor: AppColors.danger,
          textColor: textColor,
          subtitleColor: subtitleColor,
          isDark: isDark,
        ),
        _routeInfoRow(
          icon: Icons.error_outline_rounded,
          label: "Zonas medias",
          value: "${_safeRouteResult!.bestRoute.mediumZonesCrossed}",
          iconColor: AppColors.warning,
          textColor: textColor,
          subtitleColor: subtitleColor,
          isDark: isDark,
        ),
        _routeInfoRow(
          icon: Icons.check_circle_outline_rounded,
          label: "Zonas seguras",
          value: "${_safeRouteResult!.bestRoute.lowZonesCrossed}",
          iconColor: AppColors.success,
          textColor: textColor,
          subtitleColor: subtitleColor,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _mapActionButton(
          icon: Icons.close_rounded,
          label: "Cerrar ruta",
          color: AppColors.danger,
          onPressed: _clearSafeRoute,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildZoneActions({required bool isDark}) {
    final selectedZone = _selectedZone!;
    final accentColor = isDark ? AppColors.secondaryDark : AppColors.primary;
    final isFavorite =
        selectedZone.grid?.id != null &&
        _favoriteGridIds.contains(selectedZone.grid!.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 330;
        final buttonWidth = useTwoColumns
            ? (constraints.maxWidth - 10) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: buttonWidth,
              child: _mapActionButton(
                icon: Icons.route_rounded,
                label: "Ruta Segura",
                color: accentColor,
                filled: true,
                onPressed: () => _requestSafeRoute(
                  LatLng(
                    selectedZone.grid!.centroLat!,
                    selectedZone.grid!.centroLon!,
                  ),
                ),
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: buttonWidth,
              child: _mapActionButton(
                icon: Icons.reviews_rounded,
                label: "Ver Reseñas",
                color: AppColors.accent,
                foregroundColor: isDark ? AppColors.black : AppColors.black,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ZoneReviewsScreen(
                        gridId: selectedZone.grid!.id,
                        zoneName: selectedZone.grid!.nombre,
                      ),
                    ),
                  );
                },
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: buttonWidth,
              child: _mapActionButton(
                icon: Icons.local_police_rounded,
                label: "Comisarías",
                color: AppColors.info,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NearbyPoliceStationsScreen(
                        lat: selectedZone.grid!.centroLat!,
                        lon: selectedZone.grid!.centroLon!,
                      ),
                    ),
                  );
                },
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: buttonWidth,
              child: _mapActionButton(
                icon: isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: isFavorite ? "Quitar favorito" : "Favorito",
                color: AppColors.danger,
                onPressed: _favoritesLoading ? null : _toggleFavoriteZone,
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectedZoneCard({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
  }) {
    final selectedZone = _selectedZone!;
    final riskColor = _getColor(selectedZone.nivelRiesgo);
    final accentColor = isDark ? AppColors.secondaryDark : AppColors.primary;

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.42,
        ),
        margin: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: riskColor.withValues(alpha: isDark ? 0.34 : 0.22),
          ),
          boxShadow: _softShadow(isDark),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Positioned(
                top: -52,
                right: -46,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: riskColor.withValues(alpha: isDark ? 0.12 : 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -46,
                left: -42,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: isDark ? 0.08 : 0.05),
                  ),
                ),
              ),
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(17),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: riskColor.withValues(
                              alpha: isDark ? 0.18 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: riskColor.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: riskColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedZone.grid?.nombre ?? "Zona sin nombre",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              height: 1.18,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _riskChip(selectedZone.nivelRiesgo),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _closeZoneCard(),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: borderColor.withValues(
                                alpha: isDark ? 0.28 : 0.55,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: subtitleColor,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.backgroundDark.withValues(alpha: 0.40)
                            : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: borderColor.withValues(
                            alpha: isDark ? 0.45 : 0.75,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          _zoneMetricRow(
                            icon: Icons.security_rounded,
                            label: "Nivel",
                            value: _formatRiskLevel(selectedZone.nivelRiesgo),
                            iconColor: riskColor,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                          _zoneMetricRow(
                            icon: Icons.speed_rounded,
                            label: "Riesgo",
                            value: "${selectedZone.scoreRiesgo}/3",
                            iconColor: AppColors.warning,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                          _zoneMetricRow(
                            icon: Icons.calendar_today_outlined,
                            label: "Última predicción",
                            value:
                                selectedZone.fechaPrediccion
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
                    const SizedBox(height: 15),
                    if (_isCalculatingRoute) ...[
                      Center(
                        child: CircularProgressIndicator(
                          color: isDark
                              ? AppColors.secondaryDark
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          "Calculando la ruta más segura...",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: subtitleColor,
                          ),
                        ),
                      ),
                    ] else if (_safeRouteResult == null) ...[
                      _buildZoneActions(isDark: isDark),
                    ] else ...[
                      _buildSafeRouteResult(
                        isDark: isDark,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                    ],
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
          _appBarActionButton(
            icon: Icons.local_police_rounded,
            tooltip: "Probar alerta por cercanía a comisaría",
            onPressed: _testPoliceStationNotificationNearCurrentLocation,
          ),
          _appBarActionButton(
            icon: Icons.add_alert_rounded,
            tooltip: "Inyectar zona peligrosa cerca",
            onPressed: _injectTestDangerZoneNearCurrentLocation,
          ),
          _appBarActionButton(
            icon: Icons.favorite_rounded,
            tooltip: "Zonas favoritas",
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
          const SizedBox(width: 4),
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
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? AppColors.secondaryDark : AppColors.primary,
              ),
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
                  _buildSelectedZoneCard(
                    isDark: isDark,
                    cardColor: cardColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    borderColor: borderColor,
                  ),
              ],
            ),
    );
  }
}
