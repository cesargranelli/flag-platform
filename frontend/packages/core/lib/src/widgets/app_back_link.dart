import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Link de navegação "voltar" hierárquica (issue #435).
///
/// Substitui o breadcrumb removido na #433: ícone [Icons.arrow_back] (20px,
/// `primary`) + rótulo contextual com sublinhado em
/// [AppTextStyles.labelMedium] (cor `primary`). O destino é derivado da rota
/// via `context.go` (sem pilha no admin_web) e informado pelo chamador
/// ([AppScreen.backTarget]).
///
/// Alvo de toque com altura mínima de 48px (design system) via [InkWell] com
/// a tinta padrão do tema (regra #300 — sem hover/splash customizados).
class AppBackLink extends StatelessWidget {
  const AppBackLink({
    super.key,
    this.label,
    required this.onPressed,
  });

  /// Rótulo contextual do destino (ex.: "Organizações"). Quando nulo, usa
  /// [AppStrings.back] ('Voltar').
  final String? label;

  /// Ação ao tocar no link (navegação hierárquica definida pelo chamador).
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final text = label ?? AppStrings.back;
    return Semantics(
      button: true,
      label: label == null ? AppStrings.back : 'Voltar para $label',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_back,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}