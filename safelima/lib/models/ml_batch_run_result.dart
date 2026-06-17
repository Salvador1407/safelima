class MlBatchRunResult {
  final int gridsProcessed;
  final int predictionsUpdated;
  final List<String> errors;
  final DateTime? ranAt;
  final List<String> tramoHorarios;

  const MlBatchRunResult({
    required this.gridsProcessed,
    required this.predictionsUpdated,
    required this.errors,
    required this.ranAt,
    required this.tramoHorarios,
  });

  factory MlBatchRunResult.fromJson(Map<String, dynamic> json) {
    return MlBatchRunResult(
      gridsProcessed: (json['grids_processed'] is num)
          ? (json['grids_processed'] as num).toInt()
          : 0,
      predictionsUpdated: (json['predictions_updated'] is num)
          ? (json['predictions_updated'] as num).toInt()
          : 0,
      errors: (json['errors'] as List? ?? [])
          .map((item) => item.toString())
          .toList(),
      ranAt: json['ran_at'] != null
          ? DateTime.tryParse(json['ran_at'].toString())
          : null,
      tramoHorarios: (json['tramo_horarios'] as List? ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}
