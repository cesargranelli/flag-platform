import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Tema Material 3 padrão do Flag Platform.
///
/// Estrutura visual alinhada ao style guide e aos componentes do UI Kit
/// "Shifty": botões raio 16 e altura 56, inputs raio 16, chips raio 10,
/// checkboxes raio 2, cards raio 16 e escala tipográfica DM Sans.
class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      // DM Sans (tipografia da marca) aplicada via google_fonts no textTheme
      // abaixo. O pacote busca a fonte em runtime com cache HTTP; sem rede,
      // o app cai na fonte padrão da plataforma sem quebrar nada. Bundle
      // local da fonte segue como opção futura, se necessário.
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white, size: 24),
      ),
      textTheme: _textTheme(GoogleFonts.dmSansTextTheme(base.textTheme)),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        // Rótulo flutuante 12/16 ls−0.2 com opacidade @40% da spec (fieldLabel).
        labelStyle: AppTextStyles.fieldLabel.copyWith(
          color: AppColors.textPrimary.withValues(alpha: 0.4),
        ),
        border: _inputBorder(AppColors.textPrimary),
        // Habilitado: 1px Main/Dark da spec (issue #269).
        enabledBorder: _inputBorder(AppColors.textPrimary),
        focusedBorder: _inputBorder(AppColors.primary),
        disabledBorder: _inputBorder(AppColors.disabled),
        errorBorder: _inputBorder(AppColors.danger),
        focusedErrorBorder: _inputBorder(AppColors.danger),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.textPrimary,
          minimumSize: const Size(88, 56),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.textPrimary,
          minimumSize: const Size(88, 56),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(88, 56),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        side: BorderSide(color: AppColors.black),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(color: AppColors.black),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.grayFill,
        ),
        side: const BorderSide(color: AppColors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  static InputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: _style(
        base.displayLarge,
        fontSize: 36,
        height: 46 / 36,
        weight: FontWeight.w700,
        letterSpacing: -1.6,
      ),
      headlineMedium: _style(base.headlineMedium, fontSize: 24, height: 34 / 24, weight: FontWeight.w700),
      headlineSmall: _style(base.headlineSmall, fontSize: 22, height: 32 / 22, weight: FontWeight.w700),
      titleLarge: _style(base.titleLarge, fontSize: 18, height: 28 / 18, weight: FontWeight.w700),
      titleMedium: _style(base.titleMedium, fontSize: 16, height: 26 / 16, weight: FontWeight.w700),
      titleSmall: _style(base.titleSmall, fontSize: 14, height: 24 / 14, weight: FontWeight.w700),
      bodyLarge: _style(base.bodyLarge, fontSize: 18, height: 28 / 18, weight: FontWeight.w400),
      bodyMedium: _style(base.bodyMedium, fontSize: 16, height: 26 / 16, weight: FontWeight.w400),
      bodySmall: _style(base.bodySmall, fontSize: 14, height: 24 / 14, weight: FontWeight.w400),
    );
  }

  static TextStyle? _style(
    TextStyle? base, {
    required double fontSize,
    required double height,
    required FontWeight weight,
    double? letterSpacing,
  }) {
    return (base ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      height: height,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: AppColors.textPrimary,
    );
  }

  const AppTheme._();
}
