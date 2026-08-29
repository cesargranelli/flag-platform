import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Decoração padrão dos campos do kit Kickster (issue #445).
///
/// Medidas EXATAS do Figma (node `Element` 23:169): altura ~52px
/// (`contentPadding` 16×14), raio **24** (pill), fundo `surface`, borda
/// `#DADADA` em repouso, rótulo 14px SemiBold `grayLabel` quando não focado
/// e ícones 18px `disabled` (`#9ca4ab`).
///
/// Aplicada via `decoration` próprio nos wrappers do core
/// ([KicksterInput], [KicksterDropdown]) — o `InputDecorationTheme` global
/// permanece intacto.
InputDecoration kicksterFieldDecoration({
  String? labelText,
  String? hintText,
  String? helperText,
  IconData? prefixIcon,
  Widget? suffixIcon,
  Widget? prefix,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    helperText: helperText,
    helperStyle: AppTextStyles.fieldLabel.copyWith(
      color: AppColors.textSecondary,
    ),
    filled: true,
    fillColor: AppColors.surface,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    // Rótulo em repouso (dentro do campo, vazio e sem foco): 14px SemiBold.
    labelStyle: AppTextStyles.paragraph.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.grayLabel,
    ),
    // Rótulo flutuante (focado ou com texto): compacto, cor da marca.
    floatingLabelStyle: AppTextStyles.fieldLabel.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.primary,
    ),
    hintStyle: AppTextStyles.fieldLabel.copyWith(color: AppColors.disabled),
    prefixIcon: prefix ??
        (prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 18, color: AppColors.disabled)),
    prefixIconColor: AppColors.disabled,
    suffixIcon: suffixIcon == null
        ? null
        : IconTheme(
            data: const IconThemeData(size: 18, color: AppColors.disabled),
            child: suffixIcon,
          ),
    suffixIconColor: AppColors.disabled,
    border: _fieldBorder(AppColors.fieldBorder),
    enabledBorder: _fieldBorder(AppColors.fieldBorder),
    focusedBorder: _fieldBorder(AppColors.primary, width: 2),
    disabledBorder: _fieldBorder(AppColors.disabled),
    errorBorder: _fieldBorder(AppColors.danger),
    focusedErrorBorder: _fieldBorder(AppColors.danger, width: 2),
  );
}

OutlineInputBorder _fieldBorder(Color color, {double width = 1.0}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),
    borderSide: BorderSide(color: color, width: width),
  );
}
