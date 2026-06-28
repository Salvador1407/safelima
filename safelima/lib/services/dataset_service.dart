import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dataset.dart';
import 'package:safelima/core/api_config.dart';

class DatasetService {
  final String baseUrl = ApiConfig.endpoint('/datasets');

  Future<void> createDataset(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (![200, 201, 204].contains(response.statusCode)) {
      throw Exception("Error al crear dataset");
    }
  }

  Future<List<Dataset>> getAllDatasets() async {
    final response = await http.get(Uri.parse("$baseUrl/"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Dataset.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener datasets");
    }
  }

  Future<Dataset> getDatasetById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return Dataset.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al obtener dataset");
    }
  }

  Future<void> updateDataset(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (![200, 201, 204].contains(response.statusCode)) {
      throw Exception("Error al actualizar dataset");
    }
  }

  Future<Dataset> patchDataset(int id, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      return Dataset.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al aplicar patch en dataset");
    }
  }

  Future<void> deleteDataset(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (![200, 204].contains(response.statusCode)) {
      throw Exception("Error al eliminar dataset");
    }
  }
}
