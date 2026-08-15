import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema Material 3 padrão do Flag Platform.
class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      // DM Sans é a tipografia da marca; o bundle da fonte será adicionado em
      // tarefa futura (Google Fonts). Até lá, o Flutter usa a fonte padrão.
      fontFamily: 'DM Sans',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.textSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.5)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  const AppTheme._();
}
