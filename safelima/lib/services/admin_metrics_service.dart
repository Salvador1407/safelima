import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safelima/models/admin_metrics_model.dart';

class AdminMetricsService {
  final String baseUrl =
      "https://safelima-backend-1010928585686.us-central1.run.app/alerts";

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
