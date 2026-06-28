import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safelima/models/admin_metrics_model.dart';
import 'package:safelima/core/api_config.dart';

class AdminMetricsService {
  final String baseUrl = ApiConfig.endpoint('/alerts');

  Future<AdminMetricsModel> getMetrics() async {
    final response = await http.get(
      Uri.parse("$baseUrl/metrics/advanced"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception("Error al obtener métricas avanzadas");
    }

    final data = json.decode(response.body);
    return AdminMetricsModel.fromJson(data);
  }
}
