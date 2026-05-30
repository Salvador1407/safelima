import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/prediction_grid.dart';

class PredictionGridService {
  final String baseUrl =
      "https://safelima-backend-1010928585686.us-central1.run.app/predictions";

  // CREATE (POST)
  Future<void> createPrediction(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    if (![200, 201, 204].contains(response.statusCode)) {
      throw Exception("Error al crear predicción de grid");
    }
  }

  // GET ALL
  Future<List<PredictionGrid>> getAllPredictions() async {
    final response = await http
        .get(Uri.parse("$baseUrl/"))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) {
        try {
          return PredictionGrid.fromJson(json);
        } catch (_) {
          return PredictionGrid(
            id: -1,
            gridId: -1,
            scoreRiesgo: 0,
            nivelRiesgo: "desconocido",
          );
        }
      }).toList();
    } else {
      throw Exception("Error al obtener predicciones");
    }
  }

  // GET BY ID
  Future<PredictionGrid> getPredictionById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return PredictionGrid.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al obtener predicción con id $id");
    }
  }

  // UPDATE (PUT)
  Future<void> updatePrediction(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    if (![200, 201, 204].contains(response.statusCode)) {
      throw Exception("Error al actualizar predicción");
    }
  }

  // PATCH (actualización parcial)
  Future<PredictionGrid> patchPrediction(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return PredictionGrid.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception("Predicción no encontrada (id: $id)");
    } else {
      throw Exception("Error al aplicar patch en predicción");
    }
  }

  // DELETE
  Future<void> deletePrediction(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (![200, 204].contains(response.statusCode)) {
      throw Exception("Error al eliminar predicción");
    }
  }
}
