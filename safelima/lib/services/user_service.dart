import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:safelima/core/app_data.dart';
import 'package:safelima/models/citizen.dart';
import '../models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safelima/core/api_config.dart';

class RegisterCitizenException implements Exception {
  final String message;
  final int? statusCode;

  const RegisterCitizenException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class LoginException implements Exception {
  final String message;
  final int? statusCode;

  const LoginException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class UserService {
  final String baseUrl = ApiConfig.endpoint('/users');

  Future<User> createUser(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    print("🧩 [UserService] STATUS: ${response.statusCode}");
    print("🧩 [UserService] BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return User.fromJson(data);
    } else if (response.statusCode == 204) {
      throw Exception(
        "El servidor devolvió 204 (sin contenido). No se creó el usuario correctamente.",
      );
    } else {
      throw Exception(
        "Error al crear usuario (${response.statusCode}): ${response.body}",
      );
    }
  }

  Future<Map<String, dynamic>> registerCitizen({
    required String username,
    required String password,
    required String fullName,
    required String correo,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register-citizen'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
              'full_name': fullName.trim(),
              'correo': correo.trim().toLowerCase(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        if (response.body.isEmpty) return <String, dynamic>{};
        final data = jsonDecode(response.body);
        return data is Map<String, dynamic> ? data : <String, dynamic>{};
      }

      if (response.statusCode == 409) {
        String message = 'El usuario o correo ya se encuentra registrado';

        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic> && data['detail'] is String) {
            message = data['detail'];
          }
        } catch (_) {}

        throw RegisterCitizenException(
          message,
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode == 400 || response.statusCode == 422) {
        throw RegisterCitizenException(
          'Verifica los datos ingresados',
          statusCode: response.statusCode,
        );
      }

      throw RegisterCitizenException(
        'Error del servidor. Inténtalo nuevamente',
        statusCode: response.statusCode,
      );
    } on RegisterCitizenException {
      rethrow;
    } on TimeoutException {
      throw const RegisterCitizenException(
        'Error del servidor. Inténtalo nuevamente',
      );
    } on SocketException {
      throw const RegisterCitizenException('No tienes conexión a internet');
    } on http.ClientException {
      throw const RegisterCitizenException('No tienes conexión a internet');
    } on FormatException {
      throw const RegisterCitizenException(
        'Error del servidor. Inténtalo nuevamente',
      );
    }
  }

  Future<List<User>> getAllUsers() async {
    final response = await http.get(Uri.parse("$baseUrl/"));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener usuarios");
    }
  }

  Future<User> getUserById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al obtener usuario con id $id");
    }
  }

  Future<User> getUserByIdLogin(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/getUserLogin/$id"));
    if (response.statusCode == 200) {
      return User.fromJsonLogin(json.decode(response.body));
    } else {
      throw Exception("Error al obtener usuario con id $id");
    }
  }

  Future<void> updateUser(int id, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    print("Entro a patch");

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      print("Resultado modificado correctamente");
    } else {
      throw Exception("Error al crear registro emocional");
    }
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Error al eliminar usuario");
    }
  }

  //Funcionalidad
  Future<List<User>> getUsersCitizen() async {
    final response = await http.get(Uri.parse("$baseUrl/UsersCitizen/"));
    print("response");
    print(response);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener usuarios");
    }
  }

  Future<Citizen> usersDetail(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/UsersDetail/$id"));
    if (response.statusCode == 200) {
      return Citizen.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al obtener usuario con id $id");
    }
  }

  Future<Metricas> getMetricas() async {
    final response = await http.get(Uri.parse("$baseUrl/metricas/"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Metricas.fromJson(data);
    } else {
      throw Exception("Error al obtener métricas");
    }
  }

  //FORGOT & RESET PASSWORD
  Future<String> forgotPassword(String correo) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'correo': correo}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'];
      } else if (response.statusCode == 404) {
        throw Exception("Correo no registrado");
      } else {
        throw Exception("No se pudo enviar el código");
      }
    } on TimeoutException {
      throw Exception("No se pudo enviar el código");
    } on SocketException {
      throw Exception("No se pudo enviar el código");
    } on http.ClientException {
      throw Exception("No se pudo enviar el código");
    } on FormatException {
      throw Exception("No se pudo enviar el código");
    }
  }

  Future<String> resetPassword(String codigo, String newPassword) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/reset-password"),
            headers: {"Content-Type": "application/json"},
            body: json.encode({"codigo": codigo, "new_password": newPassword}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["message"] ?? "Contraseña actualizada correctamente";
      } else if (response.statusCode == 400) {
        throw Exception("Código inválido o expirado");
      } else {
        throw Exception("No se pudo actualizar la contraseña");
      }
    } on TimeoutException {
      throw Exception("No se pudo actualizar la contraseña");
    } on SocketException {
      throw Exception("No se pudo actualizar la contraseña");
    } on http.ClientException {
      throw Exception("No se pudo actualizar la contraseña");
    } on FormatException {
      throw Exception("No se pudo actualizar la contraseña");
    }
  }
}

class AuthService {
  final String baseUrl = ApiConfig.endpoint('/users');

  final _storage = const FlutterSecureStorage();

  Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data["access_token"];

      // ✅ Guardar token e IDs
      await _storage.write(key: "auth_token", value: token);
      await _storage.write(key: "user_id", value: data["id"].toString());

      // Manejar null para citizen_id
      final citizenId = data["citizen_id"];
      if (citizenId != null) {
        await _storage.write(key: "citizen_id", value: citizenId.toString());
        AppData.citizen_id = citizenId;
      } else {
        await _storage.delete(key: "citizen_id"); // limpia si no es ciudadano
        AppData.citizen_id = 0;
      }

      // Guardar role
      final role = data["role"];
      if (role != null) {
        await _storage.write(key: "role", value: role);
        AppData.role = role;
      }

      // Guardar en memoria
      AppData.userID = data["id"];
      AppData.token = token;

      return token;
    }

    if (response.statusCode == 404) {
      throw LoginException(
        "Usuario o contraseña incorrecta. Inténtalo de nuevo",
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode == 401) {
      throw LoginException(
        "Usuario o contraseña incorrecta. Inténtalo de nuevo",
        statusCode: response.statusCode,
      );
    }

    print("Error al iniciar sesión: ${response.body}");
    return null;
  }

  Future<void> logout() async {
    await _storage.delete(key: "auth_token"); // ✅ eliminar
  }

  Future<String?> getToken() async {
    return await _storage.read(key: "auth_token");
  }
}
