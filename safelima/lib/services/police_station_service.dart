import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safelima/models/policestations.dart';

class PoliceStationService {
  final String baseUrl = "http://192.168.0.7:8080/policestations";

  Future<List<PoliceStation>> getNearby({
    required double lat,
    required double lon,
    int limit = 5,
  }) async {
    final url = Uri.parse("$baseUrl/nearby?lat=$lat&lon=$lon&limit=$limit");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => PoliceStation.fromJson(e)).toList();
    } else {
      throw Exception("Error al obtener comisarías cercanas");
    }
  }

  Future<List<PoliceStation>> getAll() async {
    final url = Uri.parse(baseUrl);

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => PoliceStation.fromJson(e)).toList();
    } else {
      throw Exception("Error al obtener todas las comisarías");
    }
  }
}
