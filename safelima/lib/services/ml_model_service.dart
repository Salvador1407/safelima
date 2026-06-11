import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ml_model.dart';

class MlModelService {
  final String baseUrl =
      "https://safelima-backend-1010928585686.us-central1.run.app/models";

  Future<void> createModel(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (![200, 201, 204].contains(response.statusCode)) {
      throw Exception("Error al crear modelo ML");
    }
  }

  Future<List<MlModel>> getAllModels() async {
    final response = await http.get(Uri.parse("$baseUrl/"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => MlModel.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener modelos ML");
    }
  }

  Future<MlModel> getModelById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return MlModel.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al obtener modelo ML");
    }
  }

  Future<void> updateModel(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (![200, 201, 204].contains(response.statusCode)) {
      throw Exception("Error al actualizar modelo ML");
    }
  }

  Future<MlModel> patchModel(int id, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      return MlModel.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al aplicar patch en modelo ML");
    }
  }

  Future<void> deleteModel(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (![200, 204].contains(response.statusCode)) {
      throw Exception("Error al eliminar modelo ML");
    }
  }
}
