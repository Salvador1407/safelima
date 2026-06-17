import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safelima/core/api_config.dart';
import '../models/user_alert.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class UserAlertService {
  final String baseUrl = ApiConfig.endpoint('/alerts');

  // CREATE (POST)
  Future<void> createAlert(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    print("🔹 Enviando alerta a: $baseUrl/");
    print("🔹 Body: ${json.encode(body)}");
    print("🔹 Código: ${response.statusCode}");
    print("🔹 Respuesta: ${response.body}");

    if (![200, 201, 204].contains(response.statusCode)) {
      throw Exception("Error al crear alerta");
    }
  }

  Future<void> createAlertMultipart({
    required Map<String, String> fields,
    File? imageFile,
  }) async {
    final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/"));

    request.fields.addAll(fields);

    if (imageFile != null) {
      // Extraemos la extensión para determinar el subtipo (jpg, png, etc)
      String extension = imageFile.path.split('.').last.toLowerCase();
      if (extension == "jpg") extension = "jpeg"; // Normalizar para MIME type

      request.files.add(
        await http.MultipartFile.fromPath(
          "foto",
          imageFile.path,
          contentType: MediaType(
            'image',
            extension,
          ), // Esto fuerza "image/jpeg", "image/png", etc.
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print("🔹 Enviando alerta a: $baseUrl/");
    print("🔹 Fields: ${request.fields}");
    print("🔹 Código: ${response.statusCode}");
    print("🔹 Respuesta: ${response.body}");

    if (![200, 201].contains(response.statusCode)) {
      throw Exception("Error al crear alerta: ${response.body}");
    }
  }

  // GET ALL
  Future<List<UserAlert>> getAllAlerts() async {
    final response = await http.get(Uri.parse("$baseUrl/"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => UserAlert.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener alertas");
    }
  }

  // GET BY ID
  Future<UserAlert> getAlertById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return UserAlert.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al obtener alerta con id $id");
    }
  }

  // UPDATE (PUT)
  Future<void> updateAlertMultipart({
    required int id,
    required Map<String, String> fields,
    File? imageFile,
  }) async {
    final request = http.MultipartRequest("PUT", Uri.parse("$baseUrl/$id"));
    request.fields.addAll(fields);

    if (imageFile != null) {
      String extension = imageFile.path.split('.').last.toLowerCase();
      if (extension == "jpg") extension = "jpeg";

      request.files.add(
        await http.MultipartFile.fromPath(
          "foto",
          imageFile.path,
          contentType: MediaType('image', extension),
        ),
      );
    }

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Error al actualizar: ${response.body}");
    }
  }

  // PATCH (actualización parcial)
  Future<UserAlert> patchAlert(int id, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return UserAlert.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception("Alerta no encontrada (id: $id)");
    } else {
      throw Exception("Error al aplicar patch en alerta");
    }
  }

  Future<void> updateAlertStatus({
    required int alertId,
    required String estado,
  }) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/$alertId"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"estado": estado}),
    );

    print("PATCH => $baseUrl/$alertId");
    print("Body => ${json.encode({"estado": estado})}");
    print("Código => ${response.statusCode}");
    print("Respuesta => ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Error al actualizar estado");
    }
  }

  // DELETE
  Future<void> deleteAlert(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (![200, 204].contains(response.statusCode)) {
      throw Exception("Error al eliminar alerta");
    }
  }

  //FUNCIONALIDADES
  Future<List<UserAlert>> getAlertsByCitizen(int citizenId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/citizen/$citizenId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => UserAlert.fromJsonCitizenAlerts(e)).toList();
    } else {
      throw Exception('Error al obtener reportes del usuario');
    }
  }
}
