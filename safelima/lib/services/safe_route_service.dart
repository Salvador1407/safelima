import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safelima/models/safe_route_model.dart';
import 'package:safelima/core/api_config.dart';

class SafeRouteService {
  final String baseUrl = ApiConfig.endpoint('/routes');

  Future<SafeRouteModel> getSafeRoute({
    required double originLat,
    required double originLon,
    required double destinationLat,
    required double destinationLon,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/safe"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "origin_lat": originLat,
        "origin_lon": originLon,
        "destination_lat": destinationLat,
        "destination_lon": destinationLon,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Error al obtener ruta segura: ${response.body}");
    }

    final data = jsonDecode(response.body);
    return SafeRouteModel.fromJson(data);
  }
}
