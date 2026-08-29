import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Radio button no estilo do kit Kickster (issue #447).
///
/// Medidas do Figma (Element 23:169):
/// - Não selecionado: 24×24, borda `1px` `#E3E9ED` (Gray/G30), sem fundo;
/// - Selecionado: círculo externo 24×24 com borda `1px` `primary`
///   (`#083879`) + círculo interno de **16px** com fundo `primary`.
///
/// Controle simples (`selected: bool` + `onChanged`) — para grupos, o pai
/// decide o valor por item. Alvo de toque ≥ 48×48 (WCAG): círculo de 24px
/// centralizado num `InkWell` circular de 48×48, tinta padrão do tema (#300).
/// Semantics completa (`selected`, `enabled`, `label`) e label opcional ao
/// lado (8px de gap).
class KicksterRadioButton extends StatelessWidget {
  const KicksterRadioButton({
    super.key,
    required this.selected,
    required this.onChanged,
    this.label,
    this.semanticsLabel,
  });

  /// Estado selecionado/não selecionado.
  final bool selected;

  /// Callback ao alternar. `null` desabilita o controle.
  final ValueChanged<bool>? onChanged;

  /// Rótulo visual exibido ao lado do radio (opcional).
  final String? label;

  /// Rótulo lido por leitores de tela; quando ausente, usa [label].
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = semanticsLabel ?? label;

    final radio = Semantics(
      selected: selected,
      enabled: onChanged != null,
      label: effectiveLabel,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!selected),
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
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.fieldBorderLight,
                  width: 1,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );

    if (label == null) return radio;

    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          radio,
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