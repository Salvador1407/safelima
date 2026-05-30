class AppFeedback {
  final int? id;
  final int citizenId;
  final int estrellas;
  final String? comentario;
  final DateTime? fecha;

  AppFeedback({
    this.id,
    required this.citizenId,
    required this.estrellas,
    this.comentario,
    this.fecha,
  });

  factory AppFeedback.fromJson(Map<String, dynamic> json) {
    return AppFeedback(
      id: json['id'],
      citizenId: json['citizen_id'],
      estrellas: json['estrellas'],
      comentario: json['comentario'],
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'citizen_id': citizenId,
      'estrellas': estrellas,
      'comentario': comentario,
    };
  }
}
