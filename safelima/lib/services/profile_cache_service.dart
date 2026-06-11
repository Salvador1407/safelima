import 'dart:convert';

import 'package:safelima/models/citizen.dart';
import 'package:safelima/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileCacheService {
  static const String _keyPrefix = 'profile_cache_citizen_';

  String _keyForCitizen(int citizenId) => '$_keyPrefix$citizenId';

  Future<void> saveProfile({
    required int citizenId,
    required Citizen citizen,
  }) async {
    if (citizenId <= 0) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = citizen.userId ?? citizen.user?.id;
    final username = citizen.user?.nameuser.trim();

    final data = <String, dynamic>{
      'citizenId': citizenId,
      'fullName': citizen.fullName,
      'correo': citizen.correo,
    };

    if (userId != null) {
      data['userId'] = userId;
    }

    if (username != null && username.isNotEmpty) {
      data['username'] = username;
    }

    await prefs.setString(_keyForCitizen(citizenId), jsonEncode(data));
  }

  Future<Citizen?> getProfile(int citizenId) async {
    if (citizenId <= 0) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final rawProfile = prefs.getString(_keyForCitizen(citizenId));

    if (rawProfile == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawProfile);
      if (decoded is! Map) {
        return null;
      }

      final data = Map<String, dynamic>.from(decoded);
      final cachedCitizenId = _asInt(data['citizenId']);

      if (cachedCitizenId != citizenId) {
        return null;
      }

      final fullName = _asString(data['fullName']);
      final correo = _asString(data['correo']);

      if ((fullName == null || fullName.isEmpty) &&
          (correo == null || correo.isEmpty)) {
        return null;
      }

      final userId = _asInt(data['userId']);
      final username = _asString(data['username']);

      return Citizen(
        id: citizenId,
        userId: userId,
        fullName: fullName,
        correo: correo,
        user: username == null || username.isEmpty
            ? null
            : User(id: userId ?? 0, nameuser: username),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? _asString(Object? value) {
    if (value is! String) return null;
    final trimmedValue = value.trim();
    return trimmedValue.isEmpty ? null : trimmedValue;
  }
}
