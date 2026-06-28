import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/grid.dart';
import 'package:safelima/core/api_config.dart';

class GridService {
  final String baseUrl = ApiConfig.endpoint('/grids');

  Future<void> createGrid(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (![200, 201, 204].contains(response.statusCode)) {
      throw Exception("Error al crear grid");
    }
  }

  Future<List<Grid>> getAllGrids() async {
    final response = await http.get(Uri.parse("$baseUrl/"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Grid.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener grids");
    }
  }

  Future<Grid> getGridById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return Grid.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al obtener grid");
    }
  }

  Future<void> updateGrid(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (![200, 201, 204].contains(response.statusCode)) {
      throw Exception("Error al actualizar grid");
    }
  }

  Future<Grid> patchGrid(int id, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      return Grid.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al aplicar patch en grid");
    }
  }

  Future<void> deleteGrid(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (![200, 204].contains(response.statusCode)) {
      throw Exception("Error al eliminar grid");
    }
  }
}
