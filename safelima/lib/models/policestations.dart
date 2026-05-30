class PoliceStation {
  final int id;
  final String nombre;
  final String? direccion;
  final String? telefono;
  final double latitud;
  final double longitud;
  final String? distrito;
  final DateTime? fechaRegistro;
  final double? distanciaKm;

  PoliceStation({
    required this.id,
    required this.nombre,
    this.direccion,
    this.telefono,
    required this.latitud,
    required this.longitud,
    this.distrito,
    this.fechaRegistro,
    this.distanciaKm,
  });

  factory PoliceStation.fromJson(Map<String, dynamic> json) {
    return PoliceStation(
      id: json['id'],
      nombre: json['nombre'],
      direccion: json['direccion'],
      telefono: json['telefono'],
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      distrito: json['distrito'],
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.tryParse(json['fecha_registro'])
          : null,
      distanciaKm: json['distancia_km'] != null
          ? (json['distancia_km'] as num).toDouble()
          : null,
    );
  }
}
