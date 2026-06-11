class ZoneReview {
  final int? id;
  final int calificacion;
  final String comentario;
  final DateTime? fechaPublicacion;
  final String? citizenName;
  final int? likesCount;
  final bool? isLiked;

  ZoneReview({
    this.id,
    required this.calificacion,
    required this.comentario,
    this.fechaPublicacion,
    this.citizenName,
    this.likesCount,
    this.isLiked,
  });

  factory ZoneReview.fromJson(Map<String, dynamic> json) {
    return ZoneReview(
      id: json['id'],
      calificacion: json['calificacion'],
      comentario: json['comentario'],
      fechaPublicacion: json['fecha_publicacion'] != null
          ? DateTime.parse(json['fecha_publicacion'])
          : null,
      citizenName: json['citizen_name'],
      likesCount: json['likes_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
    );
  }
}
