class RoutePoint {
  final double lat;
  final double lon;

  RoutePoint({required this.lat, required this.lon});

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }
}

class SafeRouteOption {
  final int routeIndex;
  final double distanceMeters;
  final double durationSeconds;
  final double riskScore;
  final int dangerZonesCrossed;
  final int mediumZonesCrossed;
  final int lowZonesCrossed;
  final List<RoutePoint> polyline;

  SafeRouteOption({
    required this.routeIndex,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.riskScore,
    required this.dangerZonesCrossed,
    required this.mediumZonesCrossed,
    required this.lowZonesCrossed,
    required this.polyline,
  });

  factory SafeRouteOption.fromJson(Map<String, dynamic> json) {
    return SafeRouteOption(
      routeIndex: json['route_index'],
      distanceMeters: (json['distance_meters'] as num).toDouble(),
      durationSeconds: (json['duration_seconds'] as num).toDouble(),
      riskScore: (json['risk_score'] as num).toDouble(),
      dangerZonesCrossed: json['danger_zones_crossed'],
      mediumZonesCrossed: json['medium_zones_crossed'],
      lowZonesCrossed: json['low_zones_crossed'],
      polyline: (json['polyline'] as List)
          .map((e) => RoutePoint.fromJson(e))
          .toList(),
    );
  }
}

class SafeRouteModel {
  final int bestRouteIndex;
  final SafeRouteOption bestRoute;
  final List<SafeRouteOption> alternatives;

  SafeRouteModel({
    required this.bestRouteIndex,
    required this.bestRoute,
    required this.alternatives,
  });

  factory SafeRouteModel.fromJson(Map<String, dynamic> json) {
    return SafeRouteModel(
      bestRouteIndex: json['best_route_index'],
      bestRoute: SafeRouteOption.fromJson(json['best_route']),
      alternatives: (json['alternatives'] as List)
          .map((e) => SafeRouteOption.fromJson(e))
          .toList(),
    );
  }
}