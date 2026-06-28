import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safelima/models/favorite_area.dart';
import 'package:safelima/core/api_config.dart';

class FavoriteAreaService {
  final String baseUrl = ApiConfig.endpoint('/favorites');

  Future<List<FavoriteArea>> getFavoritesByCitizen(int citizenId) async {
    final response = await http.get(Uri.parse("$baseUrl/citizen/$citizenId"));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => FavoriteArea.fromJson(e)).toList();
    } else {
      throw Exception("Error al obtener favoritos");
    }
  }

  Future<bool> isFavorite(int citizenId, int gridId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/citizen/$citizenId/grid/$gridId"),
    );

    if (response.statusCode == 200) return true;
    if (response.statusCode == 404) return false;

    throw Exception("Error al validar favorito");
  }

  Future<void> addFavorite(int citizenId, int gridId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"citizen_id": citizenId, "grid_id": gridId}),
    );

    if (response.statusCode != 201) {
      throw Exception("Error al agregar favorito");
    }
  }

  Future<void> removeFavorite(int citizenId, int gridId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/citizen/$citizenId/grid/$gridId"),
    );

    if (response.statusCode != 204) {
      throw Exception("Error al eliminar favorito");
    }
  }
}
