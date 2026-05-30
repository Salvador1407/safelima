import 'package:flutter/material.dart';

class AppColors {
  // 🌞 TEMA CLARO — Inspirado en la seguridad, confianza y limpieza visual
  static const Color primary = Color(0xFF007BFF); // Azul institucional (base)
  static const Color secundary = Color(0xFF4DB8FF); // Azul celeste (gradientes / botones)
  static const Color accent = Color(0xFFFFC107); // Amarillo alerta / información
  static const Color backgroundLight = Color(0xFFF4F8FF); // Fondo general claro
  static const Color cardLight = Color(0xFFFFFFFF); // Fondo de tarjetas / inputs
  static const Color textLight = Color(0xFF1C2833); // Texto principal oscuro
  static const Color subtitleLight = Color(0xFF5D6D7E); // Texto secundario
  static const Color borderLight = Color(0xFFD6E4F0); // Bordes suaves

  // 🌙 TEMA OSCURO — Azul profundo con acentos contrastantes
  static const Color primaryDark = Color(0xFF0D47A1); // Azul marino (barra / énfasis)
  static const Color secondaryDark = Color(0xFF64B5F6); // Azul medio para resaltar botones
  static const Color accentDark = Color(0xFFFFC107); // Amarillo mantiene visibilidad
  static const Color backgroundDark = Color(0xFF101820); // Fondo general oscuro
  static const Color cardDark = Color(0xFF1E2A38); // Tarjetas / componentes oscuros
  static const Color textDark = Color(0xFFFDFEFE); // Texto claro
  static const Color subtitleDark = Color(0xFFB0BEC5); // Texto secundario gris-azulado
  static const Color borderDark = Color(0xFF2C3E50); // Bordes y divisores

  // 🧱 COLORES NEUTROS Y DE ESTADO
  static const Color success = Color(0xFF2ECC71); // Verde confirmación
  static const Color warning = Color(0xFFFFA726); // Naranja advertencia
  static const Color danger = Color(0xFFE74C3C); // Rojo error / alerta
  static const Color info = Color(0xFF42A5F5); // Azul informativo

  // 🎨 COLORES BÁSICOS
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // 🌈 GRADIENTES — para fondos o splash
  static const LinearGradient mainGradient = LinearGradient(
    colors: [primary, secundary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [danger, Color(0xFFB71C1C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
