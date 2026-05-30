class ZoneReview {
  final int? id;
  final int? citizenId;
  final int? gridId;
  final int calificacion;
  final String comentario;
  final DateTime? fechaPublicacion;
  final String? citizenName;
  final int? likesCount;
  final bool? isLiked;

  ZoneReview({
    this.id,
    this.citizenId,
    this.gridId,
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
      citizenId: json['citizen_id'],
      gridId: json['grid_id'],
      calificacion: json['calificacion'],
      comentario: json['comentario'],
      fechaPublicacion: json['fecha_publicacion'] != null
          ? DateTime.parse(json['fecha_publicacion'])
          : null,
      citizenName: json['citizen_name'],
      likesCount: json['likes_count'],
      isLiked: json['is_liked'],
    );
  }
}