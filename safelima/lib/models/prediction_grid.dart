import 'grid.dart';

class PredictionGrid {
  final int? id;
  final int gridId;
  final int scoreRiesgo;
  final String nivelRiesgo;
  final DateTime? fechaPrediccion;
  final String? tramoHorario;
  final Grid? grid;

  PredictionGrid({
    this.id,
    required this.gridId,
    required this.scoreRiesgo,
    required this.nivelRiesgo,
    this.fechaPrediccion,
    this.tramoHorario,
    this.grid,
  });

  factory PredictionGrid.fromJson(Map<String, dynamic> json) {
    try {
      return PredictionGrid(
        id: json['id'] ?? 0,
        gridId: json['grid_id'] ?? (json['grid']?['id'] ?? 0),
        scoreRiesgo: (json['score_riesgo'] is num)
            ? (json['score_riesgo'] as num).toInt()
            : 0,
        nivelRiesgo: json['nivel_riesgo'] ?? '',
        fechaPrediccion: json['fecha_prediccion'] != null
            ? DateTime.tryParse(json['fecha_prediccion'].toString())
            : null,
        tramoHorario: json['tramo_horario']?.toString(),
        grid: json['grid'] != null ? Grid.fromPrediction(json['grid']) : null,
      );
    } catch (e) {
      print("❌ Error al parsear PredictionGrid: $e");
      print("🧩 JSON problemático: $json");
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'grid_id': gridId,
      'score_riesgo': scoreRiesgo,
      'nivel_riesgo': nivelRiesgo,
      'fecha_prediccion': fechaPrediccion?.toIso8601String(),
      'tramo_horario': tramoHorario,
    };
  }
}
