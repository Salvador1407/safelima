import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safelima/models/review_like_toggle_response.dart';

class ReviewLikeService {
  final String baseUrl = "http://192.168.0.7:8080/reviewlikes";

  Future<ReviewLikeToggleResponse> toggleLike({
    required int citizenId,
    required int reviewId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "citizen_id": citizenId,
        "review_id": reviewId,
      }),
    );

    if (response.statusCode == 200) {
      return ReviewLikeToggleResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Error al dar like: ${response.body}");
    }
  }
}