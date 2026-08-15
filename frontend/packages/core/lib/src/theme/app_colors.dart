import 'package:flutter/material.dart';

/// Paleta de cores do Flag Platform.
///
/// Marca única adotada: paleta do UI Kit "Shifty" (primário laranja,
/// fundo claro), harmonizada com cores semânticas dos kits esportivos.
class AppColors {
  static const Color primary = Color(0xFFFD6B22);
  static const Color secondary = Color(0xFFF15223);
  static const Color accent = Color(0xFFFF6628);
  static const Color success = Color(0xFF4FBF67);
  static const Color danger = Color(0xFFF04C4C);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1B1D21);
  static const Color textSecondary = Color(0xFF737373);

  // Tema escuro (telas de autenticação — referência Social Sports UI Kit).
  static const Color darkBackground = Color(0xFF102219);
  static const Color darkSurface = Color(0xFF1A2621);
  static const Color darkSurfaceAlt = Color(0xFF1F2924);
  static const Color darkBrand = Color(0xFF13EC80);
  static const Color darkTextMuted = Color(0xFF5B6F68);
  static const Color darkInputFill = Color(0x0DFFFFFF);

  const AppColors._();
}
