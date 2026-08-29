import 'package:flutter/material.dart';

/// Paleta de cores do Flag Platform.
///
/// Marca única adotada (issue #431): paleta do UI Kit "Kickster - Live Score
/// & News Sport" (azul royal `#083879` como primário, fundo claro), mapeada
/// para os tokens semânticos atuais (primary, secondary, success, danger,
/// warning, surface, text, grayscale). Substitui a paleta Shifty (laranja).
class AppColors {
  static const Color primary = Color(0xFF083879); // azul royal (marca)
  static const Color secondary = Color(0xFF17153B); // azul-escuro
  static const Color accent = Color(0xFF0A4A9E); // azul mais claro (destaques)
  static const Color success = Color(0xFF00C566);
  static const Color warning = Color(0xFFFACC15);
  static const Color danger = Color(0xFFE53935);
  static const Color background = Color(0xFFFEFEFE);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF171725);
  static const Color textSecondary = Color(0xFF66707A);
  static const Color black = Color(0xFF111111);
  static const Color disabled = Color(0xFF9CA4AB);
  static const Color grayFill = Color(0xFFECF1F6);

  /// Line — contorno de bordas claras do kit (cards, divisores).
  static const Color line = Color(0xFFE3E7EC);

  // Auxiliares do UI Kit Kickster.
  /// Texto secundário/rodapé — rgba(0,0,0,.6).
  static const Color textMuted = Color(0x99000000);

  /// Gray/G70 — labels curtas em caixa alta (divisor "OU").
  static const Color grayLabel = Color(0xFF78828A);

  /// Borda de repouso dos campos do kit (issue #445) — #DADADA.
  static const Color fieldBorder = Color(0xFFDADADA);

  /// BG Secundário — fundo azulado de cards/áreas.
  static const Color surfaceMuted = Color(0xFFF6F8FE);

  const AppColors._();
}
