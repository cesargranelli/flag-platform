import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Estilos tipográficos nomeados do design system (escala Kickster — issue
/// #431).
///
/// A família de fonte é herdada do tema (Plus Jakarta Sans via `google_fonts`
/// em [AppTheme.light]); aqui definimos apenas tamanho, altura de linha, peso,
/// letter-spacing e cor padrão da marca. Uso: `Text('...', style:
/// AppTextStyles.headline1)` — ajuste pontuais via `copyWith`.
abstract final class AppTextStyles {
  /// H1 — títulos de destaque (48/56, w700, ls 0.24).
  static const TextStyle headline1 = TextStyle(
    fontSize: 48,
    height: 56 / 48,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.24,
    color: AppColors.textPrimary,
  );

  /// Subtítulo de tela (20/28, w500, ls 0.10).
  static const TextStyle subtitle = TextStyle(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.10,
    color: AppColors.textMuted,
  );

  /// Texto médio de links e rótulos de checkbox (14/22, w500, ls 0.07).
  /// Cor definida no ponto de uso (ex.: `textPrimary`, `primary`).
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.07,
  );

  /// Parágrafo padrão (14/22, w400, ls 0.07).
  static const TextStyle paragraph = TextStyle(
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.07,
    color: AppColors.textPrimary,
  );

  /// Rótulo flutuante de campo (12/20, w400, ls 0.06). A opacidade @40%
  /// da spec é aplicada pelo `InputDecorationTheme.labelStyle` no tema.
  static const TextStyle fieldLabel = TextStyle(
    fontSize: 12,
    height: 20 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.06,
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

  /// Texto de botão primário (14/22, w700, branco).
  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.07,
    color: Colors.white,
  );

  /// Link/texto de rodapé (13/17, w500, ls 0.07, muted).
  static const TextStyle footerLink = TextStyle(
    fontSize: 13,
    height: 17 / 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.07,
    color: AppColors.textMuted,
  );
}