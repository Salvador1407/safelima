import 'package:safelima/models/grid.dart';

class FavoriteArea {
  final int? id;
  final int citizenId;
  final int gridId;
  final DateTime? fechaAgregado;
  final Grid? grid;

  FavoriteArea({
    this.id,
    required this.citizenId,
    required this.gridId,
    this.fechaAgregado,
    this.grid,
  });

  factory FavoriteArea.fromJson(Map<String, dynamic> json) {
    return FavoriteArea(
      id: json['id'],
      citizenId: json['citizen_id'],
      gridId: json['grid_id'],
      fechaAgregado: json['fecha_agregado'] != null
          ? DateTime.parse(json['fecha_agregado'])
          : null,
      grid: json['grid'] != null ? Grid.fromJson(json['grid']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {"citizen_id": citizenId, "grid_id": gridId};
  }
}
