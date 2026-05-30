class ReviewLikeToggleResponse {
  final bool liked;
  final int likesCount;
  final int reviewId;

  ReviewLikeToggleResponse({
    required this.liked,
    required this.likesCount,
    required this.reviewId,
  });

  factory ReviewLikeToggleResponse.fromJson(Map<String, dynamic> json) {
    return ReviewLikeToggleResponse(
      liked: json['liked'] ?? false,
      likesCount: json['likes_count'] ?? 0,
      reviewId: json['review_id'],
    );
  }
}