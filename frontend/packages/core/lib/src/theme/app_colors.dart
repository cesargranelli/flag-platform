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
  static const Color warning = Color(0xFFFF6628);
  static const Color danger = Color(0xFFF04C4C);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1B1D21);
  static const Color textSecondary = Color(0xFF737373);
  static const Color black = Color(0xFF040415);
  static const Color disabled = Color(0xFFD9D9D9);
  static const Color grayFill = Color(0xFFF4F5F7);

  // Auxiliares do UI Kit Shifty (spec tela de login).
  /// Texto secundário/rodapé — rgba(0,0,0,.5).
  static const Color textMuted = Color(0x80000000);

  /// Gray/G100 — labels curtas em caixa alta (divisor "OU").
  static const Color grayLabel = Color(0xFF8F92A1);

  /// Superfície neutra — fundo de botões sociais.
  static const Color surfaceMuted = Color(0xFFF3F6F8);

  const AppColors._();
}
