class Grid {
  final int id;
  final String nombre;
  final int? gridLatIdx;
  final int? gridLonIdx;
  final double? centroLat;
  final double? centroLon;

  Grid({
    required this.id,
    required this.nombre,
    this.gridLatIdx,
    this.gridLonIdx,
    this.centroLat,
    this.centroLon,
  });

  factory Grid.fromJson(Map<String, dynamic> json) {
    return Grid(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      gridLatIdx: json['grid_lat_idx'],
      gridLonIdx: json['grid_lon_idx'],
      centroLat: json['centro_lat']?.toDouble(),
      centroLon: json['centro_lon']?.toDouble(),
    );
  }

  factory Grid.fromPrediction(Map<String, dynamic> json) {
    return Grid(
      id: (json['id'] ?? 0) as int,
      nombre: json['nombre'] ?? '',
      gridLatIdx: (json['grid_lat_idx'] is int)
          ? json['grid_lat_idx']
          : (json['grid_lat_idx'] ?? 0).toInt(),
      gridLonIdx: (json['grid_lon_idx'] is int)
          ? json['grid_lon_idx']
          : (json['grid_lon_idx'] ?? 0).toInt(),
      centroLat: (json['centro_lat'] ?? 0).toDouble(),
      centroLon: (json['centro_lon'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'grid_lat_idx': gridLatIdx,
      'grid_lon_idx': gridLonIdx,
      'centro_lat': centroLat,
      'centro_lon': centroLon,
    };
  }
}
