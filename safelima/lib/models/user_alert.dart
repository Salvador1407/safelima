import 'grid.dart';

class UserAlert {
  final int? id;
  final String titulo;
  final String descripcion;
  final String? tipoIncidente;
  final String nivelRiesgo;
  final String? estado;
  final DateTime? fecha;
  final Grid? grid;
  final int? citizenId;
  final int? gridId;
  final String? rutaFoto;

  UserAlert({
    this.id,
    required this.titulo,
    required this.descripcion,
    this.tipoIncidente,
    required this.nivelRiesgo,
    this.estado,
    this.fecha,
    this.grid,
    this.citizenId,
    this.gridId,
    this.rutaFoto,
  });

  factory UserAlert.fromJson(Map<String, dynamic> json) {
    return UserAlert(
      id: json['id'],
      citizenId: json['citizen_id'], // puede venir nulo
      gridId: json['grid_id'], // puede venir nulo
      titulo: json['titulo'] ?? '',
      tipoIncidente: json['tipo_incidente'],
      descripcion: json['descripcion'] ?? '',
      nivelRiesgo: json['nivel_riesgo'] ?? 'indefinido',
      rutaFoto: json['ruta_foto'],
      estado: json['estado'],
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : null,
      grid: json['grid'] != null ? Grid.fromJson(json['grid']) : null,
    );
  }

    factory UserAlert.fromJsonCitizenAlerts(Map<String, dynamic> json) {
    return UserAlert(
      id: json['id'],
      grid: json['grid'] != null ? Grid.fromJson(json['grid']) : null,
      titulo: json['titulo'] ?? '',
      tipoIncidente: json['tipo_incidente'],
      descripcion: json['descripcion'] ?? '',
      nivelRiesgo: json['nivel_riesgo'] ?? 'indefinido',
      rutaFoto: json['ruta_foto'],
      estado: json['estado'],
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'citizen_id': citizenId,
      'grid_id': gridId,
      'titulo': titulo,
      'descripcion': descripcion,
      'nivel_riesgo': nivelRiesgo,
      'ruta_foto': rutaFoto,
      'estado': estado,
      'fecha': fecha?.toIso8601String(),
      'grid': grid?.toJson(),
    };
  }
}

class GridInfo {
  final int id;
  final String nombre;

  GridInfo({
    required this.id,
    required this.nombre,
  });

  factory GridInfo.fromJson(Map<String, dynamic> json) {
    return GridInfo(
      id: json['id'],
      nombre: json['nombre'],
    );
  }
}