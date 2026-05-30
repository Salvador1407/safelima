class Dataset {
  final int? id;
  final String? nombre;
  final String? fuente;
  final String? rutaArchivo;
  final int? numRegistros;
  final String? descripcion;
  final DateTime? fechaIngreso;

  Dataset({
    this.id,
    this.nombre,
    this.fuente,
    this.rutaArchivo,
    this.numRegistros,
    this.descripcion,
    this.fechaIngreso,
  });

  factory Dataset.fromJson(Map<String, dynamic> json) {
    return Dataset(
      id: json['id'],
      nombre: json['nombre'],
      fuente: json['fuente'],
      rutaArchivo: json['ruta_archivo'],
      numRegistros: json['num_registros'],
      descripcion: json['descripcion'],
      fechaIngreso: json['fecha_ingreso'] != null
          ? DateTime.parse(json['fecha_ingreso'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'fuente': fuente,
      'ruta_archivo': rutaArchivo,
      'num_registros': numRegistros,
      'descripcion': descripcion,
      'fecha_ingreso': fechaIngreso?.toIso8601String(),
    };
  }
}
