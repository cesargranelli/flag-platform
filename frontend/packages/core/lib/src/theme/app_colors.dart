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

  /// Borda clara de repouso dos seletores (checkbox/radio) do kit (issue
  /// #447) — Gray/G30 #E3E9ED.
  static const Color fieldBorderLight = Color(0xFFE3E9ED);

  /// BG Secundário — fundo azulado de cards/áreas.
  static const Color surfaceMuted = Color(0xFFF6F8FE);

  /// Toggle (issue #449) — trilho desligado do Figma (Element 23:169):
  /// `#EDF2F7`.
  static const Color toggleOff = Color(0xFFEDF2F7);

  // Chips de status (issue #449) — fundo + texto por variante (Figma,
  // Element 23:169). Textos em tom escuro da mesma cor para contraste
  // adequado sobre os fundos claros (WCAG AA).
  static const Color chipSuccessBg = Color(0xFFE6F9F0);
  static const Color chipSuccessFg = Color(0xFF1E8E4E);
  static const Color chipPendingBg = Color(0xFFFFF2ED);
  static const Color chipPendingFg = Color(0xFFB54708);
  static const Color chipRefundBg = Color(0xFFFFFAE8);
  static const Color chipRefundFg = Color(0xFF854D0E);
  static const Color chipFailedBg = Color(0xFFFFEDED);
  static const Color chipFailedFg = Color(0xFFC62828);
  static const Color chipUnpaidBg = Color(0xFFF4F0FF);
  static const Color chipUnpaidFg = Color(0xFF4F3BA8);

  const AppColors._();
}
