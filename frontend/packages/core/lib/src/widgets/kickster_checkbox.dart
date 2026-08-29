import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Checkbox no estilo do kit Kickster (issue #447).
///
/// Formato **circular** (não quadrado), medidas do Figma (Element 23:169):
/// - Não marcado: 24×24, borda `1px` `#E3E9ED` (Gray/G30), sem fundo;
/// - Marcado: fundo `primary` (`#083879`) + check branco (`#FEFEFE`, stroke
///   fino via `Icons.check`).
///
/// Alvo de toque ≥ 48×48 (WCAG): o círculo de 24px fica centralizado num
/// `InkWell` circular de 48×48, com tinta padrão do tema (#300). Semantics
/// completa (`checked`, `enabled`, `label`) e label opcional ao lado do
/// controle (8px de gap).
class KicksterCheckbox extends StatelessWidget {
  const KicksterCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.semanticsLabel,
  });

  /// Estado marcado/desmarcado.
  final bool value;

  /// Callback ao alternar. `null` desabilita o controle.
  final ValueChanged<bool>? onChanged;

  /// Rótulo visual exibido ao lado do checkbox (opcional).
  final String? label;

  /// Rótulo lido por leitores de tela; quando ausente, usa [label].
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = semanticsLabel ?? label;

    final checkbox = Semantics(
      checked: value,
      enabled: onChanged != null,
      label: effectiveLabel,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? AppColors.primary : null,
                border: Border.all(
                  color: value
                      ? AppColors.primary
                      : AppColors.fieldBorderLight,
                  width: 1,
                ),
              ),
              child: value
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.background, // branco #FEFEFE do kit
                    )
                  : null,
            ),
          ),
        ),
      ),
    );

    if (label == null) return checkbox;

    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          checkbox,
          const SizedBox(width: 8),
          ExcludeSemantics(
            child: Text(
              label!,
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}