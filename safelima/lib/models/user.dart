class User {
  final int id;
  final String nameuser;
  final String? password;
  final bool? enable;
  final String? role;

  User({
    required this.id,
    required this.nameuser,
    this.password,
    this.enable,
    this.role,
  });

  //toma un JSON y conviértelo en un objeto Dart.
  //Puedo crear varios factorys para manejar diferentes tipos de JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nameuser: json['username'],
      enable: json['enable'],
      role: json['role'],
      id: json['id'],
    );
  }

  factory User.fromJsonLogin(Map<String, dynamic> json) {
    return User(
      nameuser: json['username'],
      password: json['password'],
      id: json['id'],
    );
  }
  //Esto sirve cuando quieras guardar o enviar datos al servidor.
  Map<String, dynamic> toJson() {
    return {'id': id, 'username': nameuser, 'enable': enable, 'role': role};
  }
}

class Metricas {
  final int usuarios;
  final int conversaciones;
  final int recursos;

  Metricas({
    required this.usuarios,
    required this.conversaciones,
    required this.recursos,
  });

  factory Metricas.fromJson(Map<String, dynamic> json) {
    return Metricas(
      usuarios: json['usuarios'],
      conversaciones: json['conversaciones'],
      recursos: json['recursos'],
    );
  }
}
