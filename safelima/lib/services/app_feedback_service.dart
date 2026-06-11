import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safelima/models/app_feedback.dart';

class AppFeedbackService {
  final String baseUrl =
      "https://safelima-backend-1010928585686.us-central1.run.app/appfeedback";

  Future<AppFeedback> createFeedback(AppFeedback feedback) async {
    final response = await http.post(
      Uri.parse('$baseUrl/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(feedback.toJson()),
    );

    if (response.statusCode == 201) {
      return AppFeedback.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al enviar feedback: ${response.body}');
    }
  }

  Future<AppFeedback> getFeedbackByCitizen(int citizenId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/citizen/$citizenId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return AppFeedback.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('No se pudo obtener el feedback');
    }
  }

  Future<AppFeedback> updateFeedback(
    int citizenId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/citizen/$citizenId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return AppFeedback.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al actualizar feedback: ${response.body}');
    }
  }
}
