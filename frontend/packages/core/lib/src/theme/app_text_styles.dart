import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Estilos tipográficos nomeados do design system (escala Shifty).
///
/// A família de fonte é herdada do tema (DM Sans via `google_fonts` em
/// [AppTheme.light]); aqui definimos apenas tamanho, altura de linha, peso,
/// letter-spacing e cor padrão da marca. Uso: `Text('...', style:
/// AppTextStyles.headline1)` — ajuste pontuais via `copyWith`.
abstract final class AppTextStyles {
  /// H1 — títulos de destaque (36/46, w700, ls −1.6).
  static const TextStyle headline1 = TextStyle(
    fontSize: 36,
    height: 46 / 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.6,
    color: AppColors.textPrimary,
  );

  /// Subtítulo de tela (24/34, w400, ls −0.8).
  static const TextStyle subtitle = TextStyle(
    fontSize: 24,
    height: 34 / 24,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.8,
    color: AppColors.textMuted,
  );

  /// Texto médio de links e rótulos de checkbox (14/24, w500, ls −0.3).
  /// Cor definida no ponto de uso (ex.: `textPrimary`, `primary`).
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    height: 24 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.3,
  );

  /// Parágrafo padrão (14/24, w400, ls −0.3).
  static const TextStyle paragraph = TextStyle(
    fontSize: 14,
    height: 24 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  /// Rótulo flutuante de campo (12/16, w400, ls −0.2). A opacidade @40%
  /// da spec é aplicada pelo `InputDecorationTheme.labelStyle` no tema.
  static const TextStyle fieldLabel = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  /// Overline em caixa alta (12/20, w700, ls +1) — divisor "OU".
  static const TextStyle overlineLabel = TextStyle(
    fontSize: 12,
    height: 20 / 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    color: AppColors.grayLabel,
  );

  /// Texto de botão primário (14/24, w700, branco).
  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    height: 24 / 14,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: Colors.white,
  );

  /// Link/texto de rodapé (13/17, w500, ls −0.2, muted).
  static const TextStyle footerLink = TextStyle(
    fontSize: 13,
    height: 17 / 13,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
    color: AppColors.textMuted,
  );
}
