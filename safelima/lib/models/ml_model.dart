import 'dataset.dart';

class MlModel {
  final int? id;
  final String? nombreModelo;
  final int? datasetId;
  final String? version;
  final String? rutaModelo;
  final double? precision;
  final double? accuracy;
  final double? recall;
  final double? f1;
  final double? auc;
  final DateTime? fechaEntrenamiento;
  final Dataset? dataset;

  MlModel({
    this.id,
    this.nombreModelo,
    this.datasetId,
    this.version,
    this.rutaModelo,
    this.precision,
    this.accuracy,
    this.recall,
    this.f1,
    this.auc,
    this.fechaEntrenamiento,
    this.dataset,
  });

  factory MlModel.fromJson(Map<String, dynamic> json) {
    return MlModel(
      id: json['id'],
      nombreModelo: json['nombre_modelo'],
      datasetId: json['dataset_id'],
      version: json['version'],
      rutaModelo: json['ruta_modelo'],
      precision: (json['precision'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      recall: (json['recall'] as num?)?.toDouble(),
      f1: (json['f1'] as num?)?.toDouble(),
      auc: (json['auc'] as num?)?.toDouble(),
      fechaEntrenamiento: json['fecha_entrenamiento'] != null
          ? DateTime.parse(json['fecha_entrenamiento'])
          : null,
      dataset: json['dataset'] != null
          ? Dataset.fromJson(json['dataset'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre_modelo': nombreModelo,
      'dataset_id': datasetId,
      'version': version,
      'ruta_modelo': rutaModelo,
      'precision': precision,
      'accuracy': accuracy,
      'recall': recall,
      'f1': f1,
      'auc': auc,
      'fecha_entrenamiento': fechaEntrenamiento?.toIso8601String(),
    };
  }
}
