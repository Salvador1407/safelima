import 'user.dart';

class Citizen {
  final int? id;
  final int? userId;
  final String? fullName;
  final String? correo;
  final User? user;

  Citizen({this.id, this.userId, this.fullName, this.correo, this.user});

  factory Citizen.fromJson(Map<String, dynamic> json) {
    return Citizen(
      id: json['id'] as int?,
      userId: json['user_id'] as int?, // 👈 agregar esto
      fullName: json['full_name'] as String?,
      correo: json['correo'] as String?,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'full_name': fullName, 'correo': correo};
  }
}
