class StatusMetric {
  final String estado;
  final int total;

  StatusMetric({
    required this.estado,
    required this.total,
  });

  factory StatusMetric.fromJson(Map<String, dynamic> json) {
    return StatusMetric(
      estado: json['estado'] ?? '',
      total: json['total'] ?? 0,
    );
  }
}

class RiskMetric {
  final String nivelRiesgo;
  final int total;

  RiskMetric({
    required this.nivelRiesgo,
    required this.total,
  });

  factory RiskMetric.fromJson(Map<String, dynamic> json) {
    return RiskMetric(
      nivelRiesgo: json['nivel_riesgo'] ?? '',
      total: json['total'] ?? 0,
    );
  }
}

class ZoneMetric {
  final int gridId;
  final String gridNombre;
  final int total;

  ZoneMetric({
    required this.gridId,
    required this.gridNombre,
    required this.total,
  });

  factory ZoneMetric.fromJson(Map<String, dynamic> json) {
    return ZoneMetric(
      gridId: json['grid_id'] ?? 0,
      gridNombre: json['grid_nombre'] ?? '',
      total: json['total'] ?? 0,
    );
  }
}

class IncidentTypeMetric {
  final String tipoIncidente;
  final int total;

  IncidentTypeMetric({
    required this.tipoIncidente,
    required this.total,
  });

  factory IncidentTypeMetric.fromJson(Map<String, dynamic> json) {
    return IncidentTypeMetric(
      tipoIncidente: json['tipo_incidente'] ?? '',
      total: json['total'] ?? 0,
    );
  }
}

class DailyMetric {
  final String fecha;
  final int total;

  DailyMetric({
    required this.fecha,
    required this.total,
  });

  factory DailyMetric.fromJson(Map<String, dynamic> json) {
    return DailyMetric(
      fecha: json['fecha'] ?? '',
      total: json['total'] ?? 0,
    );
  }
}

class ModelMetrics {
  final int id;
  final String? nombreModelo;
  final String? version;
  final double? precision;
  final double? accuracy;
  final double? recall;
  final double? f1;
  final double? auc;
  final DateTime? fechaEntrenamiento;

  ModelMetrics({
    required this.id,
    this.nombreModelo,
    this.version,
    this.precision,
    this.accuracy,
    this.recall,
    this.f1,
    this.auc,
    this.fechaEntrenamiento,
  });

  factory ModelMetrics.fromJson(Map<String, dynamic> json) {
    return ModelMetrics(
      id: json['id'] ?? 0,
      nombreModelo: json['nombre_modelo'],
      version: json['version'],
      precision: (json['precision'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      recall: (json['recall'] as num?)?.toDouble(),
      f1: (json['f1'] as num?)?.toDouble(),
      auc: (json['auc'] as num?)?.toDouble(),
      fechaEntrenamiento: json['fecha_entrenamiento'] != null
          ? DateTime.tryParse(json['fecha_entrenamiento'])
          : null,
    );
  }
}

class AdminMetricsModel {
  final String distrito;
  final int totalReportes;
  final List<StatusMetric> porEstado;
  final List<RiskMetric> porNivelRiesgo;
  final List<ZoneMetric> porZona;
  final List<IncidentTypeMetric> porTipoIncidente;
  final List<DailyMetric> porFecha;
  final ModelMetrics? modelo;

  AdminMetricsModel({
    required this.distrito,
    required this.totalReportes,
    required this.porEstado,
    required this.porNivelRiesgo,
    required this.porZona,
    required this.porTipoIncidente,
    required this.porFecha,
    required this.modelo,
  });

  factory AdminMetricsModel.fromJson(Map<String, dynamic> json) {
    return AdminMetricsModel(
      distrito: json['distrito'] ?? 'Cercado de Lima',
      totalReportes: json['total_reportes'] ?? 0,
      porEstado: (json['por_estado'] as List? ?? [])
          .map((e) => StatusMetric.fromJson(e))
          .toList(),
      porNivelRiesgo: (json['por_nivel_riesgo'] as List? ?? [])
          .map((e) => RiskMetric.fromJson(e))
          .toList(),
      porZona: (json['por_zona'] as List? ?? [])
          .map((e) => ZoneMetric.fromJson(e))
          .toList(),
      porTipoIncidente: (json['por_tipo_incidente'] as List? ?? [])
          .map((e) => IncidentTypeMetric.fromJson(e))
          .toList(),
      porFecha: (json['por_fecha'] as List? ?? [])
          .map((e) => DailyMetric.fromJson(e))
          .toList(),
      modelo: json['modelo'] != null
          ? ModelMetrics.fromJson(json['modelo'])
          : null,
    );
  }
}