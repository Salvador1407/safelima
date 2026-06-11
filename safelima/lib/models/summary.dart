import 'zone_review.dart';

class ZoneReviewSummary {
  final int gridId;
  final int totalReviews;
  final double promedioCalificacion;
  final List<ZoneReview> reviews;

  ZoneReviewSummary({
    required this.gridId,
    required this.totalReviews,
    required this.promedioCalificacion,
    required this.reviews,
  });

  factory ZoneReviewSummary.fromJson(Map<String, dynamic> json) {
    return ZoneReviewSummary(
      gridId: json['grid_id'],
      totalReviews: json['total_reviews'],
      promedioCalificacion: (json['promedio_calificacion'] as num).toDouble(),
      reviews: (json['reviews'] as List)
          .map((item) => ZoneReview.fromJson(item))
          .toList(),
    );
  }
}
