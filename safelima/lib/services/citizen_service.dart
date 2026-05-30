import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/citizen.dart';

class CitizenService {
  final String baseUrl =
      "https://safelima-backend-1010928585686.us-central1.run.app/citizens";

  Future<Citizen> createCitizen(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    print("🧩 [CitizenService] STATUS: ${response.statusCode}");
    print("🧩 [CitizenService] BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isEmpty) {
        throw Exception(
          "El backend devolvió una respuesta vacía al crear el ciudadano.",
        );
      }
      final data = json.decode(response.body);
      return Citizen.fromJson(data);
    } else {
      throw Exception(
        "Error al crear citizen: ${response.statusCode} - ${response.body}",
      );
    }
  }

  Future<List<Citizen>> getAllCitizens() async {
    final response = await http.get(Uri.parse("$baseUrl/"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Citizen.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener ciudadanos");
    }
  }

  Future<Citizen> getCitizenById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return Citizen.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al obtener ciudadano");
    }
  }

  Future<void> updateCitizen(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (![200, 201, 204].contains(response.statusCode)) {
      throw Exception("Error al actualizar ciudadano");
    }
  }

  Future<Citizen> patchCitizen(int id, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      return Citizen.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al aplicar patch en ciudadano");
    }
  }

  Future<void> deleteCitizen(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (![200, 204].contains(response.statusCode)) {
      throw Exception("Error al eliminar ciudadano");
    }
  }
}
