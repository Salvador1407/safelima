import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:safelima/core/api_config.dart';
import 'package:safelima/core/app_data.dart';
import 'package:safelima/models/ml_batch_run_result.dart';
import 'package:safelima/models/ml_model_status.dart';
import 'package:safelima/services/user_service.dart';

class MlAdminException implements Exception {
  final String message;
  final int? statusCode;

  const MlAdminException(this.message, {this.statusCode});

  bool get isAuthError => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

class MlAdminService {
  final String baseUrl = ApiConfig.endpoint('/admin/ml');
  final AuthService _authService = AuthService();

  Future<MlModelStatus> getModelStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/models/status'), headers: await _headers())
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return MlModelStatus.fromJson(_decodeObject(response.body));
      }

      throw _exceptionFromResponse(response);
    } on MlAdminException {
      rethrow;
    } on TimeoutException {
      throw const MlAdminException('Tiempo de espera agotado');
    } on SocketException {
      throw const MlAdminException('No tienes conexión a internet');
    } on http.ClientException {
      throw const MlAdminException('No se pudo conectar con el servidor');
    } on FormatException {
      throw const MlAdminException('Respuesta inválida del servidor');
    }
  }

  Future<MlBatchRunResult> runBatchPredictions() async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/batch-predictions'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        return MlBatchRunResult.fromJson(_decodeObject(response.body));
      }

      throw _exceptionFromResponse(response);
    } on MlAdminException {
      rethrow;
    } on TimeoutException {
      throw const MlAdminException('El batch tardó más de lo esperado');
    } on SocketException {
      throw const MlAdminException('No tienes conexión a internet');
    } on http.ClientException {
      throw const MlAdminException('No se pudo conectar con el servidor');
    } on FormatException {
      throw const MlAdminException('Respuesta inválida del servidor');
    }
  }

  Future<Map<String, String>> _headers() async {
    final storedToken = await _authService.getToken();
    final token = (storedToken?.isNotEmpty == true)
        ? storedToken!
        : AppData.token;

    if (token.isEmpty) {
      throw const MlAdminException(
        'Sesión expirada. Vuelve a iniciar sesión.',
        statusCode: 401,
      );
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = json.decode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const FormatException('JSON object expected');
  }

  MlAdminException _exceptionFromResponse(http.Response response) {
    final detail = _extractDetail(response.body);

    switch (response.statusCode) {
      case 401:
        return MlAdminException(
          detail ?? 'Sesión expirada. Vuelve a iniciar sesión.',
          statusCode: response.statusCode,
        );
      case 403:
        return MlAdminException(
          detail ?? 'No tienes permisos de administrador.',
          statusCode: response.statusCode,
        );
      case 503:
        return MlAdminException(
          detail ?? 'Modelos ML no disponibles.',
          statusCode: response.statusCode,
        );
      default:
        return MlAdminException(
          detail ?? 'Error al consultar servicios ML',
          statusCode: response.statusCode,
        );
    }
  }

  String? _extractDetail(String body) {
    if (body.isEmpty) return null;

    try {
      final decoded = json.decode(body);
      if (decoded is Map && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
