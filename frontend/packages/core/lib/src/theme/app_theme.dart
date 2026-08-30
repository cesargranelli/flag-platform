import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Tema Material 3 padrão do Flag Platform.
///
/// Estrutura visual alinhada ao style guide e aos componentes do UI Kit
/// "Kickster - Live Score & News Sport" (issue #431): botões raio 16 e
/// altura 56, inputs raio 16, chips raio 10, checkboxes raio 2, cards raio
/// 16 e escala tipográfica Plus Jakarta Sans.
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
      // Plus Jakarta Sans (tipografia da marca) aplicada via google_fonts no
      // textTheme abaixo. O pacote busca a fonte em runtime com cache HTTP;
      // sem rede, o app cai na fonte padrão da plataforma sem quebrar nada.
      // Bundle local da fonte segue como opção futura, se necessário.
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
      // Canvas para menu aberto de dropdown (DropdownButtonFormField lê
      // `Theme.of(context).canvasColor` como fundo do menu — issue #365).
      canvasColor: AppColors.surface,
      textTheme: _textTheme(GoogleFonts.plusJakartaSansTextTheme(base.textTheme)),
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
        border: _inputBorder(AppColors.primary),
        // Issue #273 (validação UX): habilitado/focado usam a cor da marca —
        // a distinção de foco é por espessura (2px), não por tom. Erro segue
        // danger; desabilitado neutro.
        enabledBorder: _inputBorder(AppColors.primary),
        focusedBorder: _inputBorder(AppColors.primary, width: 2),
        disabledBorder: _inputBorder(AppColors.disabled),
        errorBorder: _inputBorder(AppColors.danger),
        focusedErrorBorder: _inputBorder(AppColors.danger, width: 2),
      ),
      // Menu aberto de dropdown com fundo branco (surface) e raio 16 (issue #365).
      // Vale para os widgets `DropdownMenu`; o `DropdownButtonFormField` ainda
      // usa `canvasColor` (definido acima) para o fundo do menu.
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
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

  static InputBorder _inputBorder(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    // Escala do Kickster (issue #431): letter-spacing = tamanho * 0.005.
    return base.copyWith(
      displayLarge: _style(
        base.displayLarge,
        fontSize: 48,
        height: 56 / 48,
        weight: FontWeight.w700,
        letterSpacing: 0.24,
      ),
      headlineMedium: _style(
        base.headlineMedium,
        fontSize: 40,
        height: 48 / 40,
        weight: FontWeight.w700,
        letterSpacing: 0.20,
      ),
      headlineSmall: _style(
        base.headlineSmall,
        fontSize: 32,
        height: 40 / 32,
        weight: FontWeight.w700,
        letterSpacing: 0.16,
      ),
      titleLarge: _style(
        base.titleLarge,
        fontSize: 24,
        height: 32 / 24,
        weight: FontWeight.w700,
        letterSpacing: 0.12,
      ),
      titleMedium: _style(
        base.titleMedium,
        fontSize: 20,
        height: 28 / 20,
        weight: FontWeight.w600,
        letterSpacing: 0.10,
      ),
      titleSmall: _style(
        base.titleSmall,
        fontSize: 18,
        height: 26 / 18,
        weight: FontWeight.w600,
        letterSpacing: 0.09,
      ),
      bodyLarge: _style(
        base.bodyLarge,
        fontSize: 16,
        height: 24 / 16,
        weight: FontWeight.w400,
        letterSpacing: 0.08,
      ),
      bodyMedium: _style(
        base.bodyMedium,
        fontSize: 14,
        height: 22 / 14,
        weight: FontWeight.w400,
        letterSpacing: 0.07,
      ),
      bodySmall: _style(
        base.bodySmall,
        fontSize: 12,
        height: 20 / 12,
        weight: FontWeight.w400,
        letterSpacing: 0.06,
      ),
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
