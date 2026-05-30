import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safelima/models/summary.dart';
import 'package:safelima/models/zone_review.dart';

class ZoneReviewService {
  final String baseUrl = "http://192.168.0.7:8080/zonereviews";

  Future<ZoneReviewSummary> getReviewsByGrid(
    int gridId, {
    int? citizenId,
  }) async {
    final uri = citizenId != null
        ? Uri.parse('$baseUrl/grid/$gridId?citizen_id=$citizenId')
        : Uri.parse('$baseUrl/grid/$gridId');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return ZoneReviewSummary.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al obtener reseñas de la zona');
    }
  }

  Future<ZoneReview> createReview(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return ZoneReview.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al publicar reseña: ${response.body}');
    }
  }
}