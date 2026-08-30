import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Toggle (switch) no estilo do kit Kickster (issue #449).
///
/// Medidas EXATAS do Figma (Element 23:169):
/// - Trilho **44×24**, raio 1000 (pill);
/// - **Off**: fundo `#EDF2F7` ([AppColors.toggleOff]), thumb branco 24×24
///   com borda `#EDF2F7` 2px;
/// - **On**: fundo `primary` (`#083879`), thumb branco 24×24 com borda
///   `primary` 2px.
///
/// Deslize do thumb via `AnimatedAlign` (150ms, easeInOut). Alvo de toque
/// ≥ 48×48 (WCAG): o pill de 44×24 fica centralizado num `InkWell` de
/// 48×48, com tinta padrão do tema. Semantics completa (`toggled`,
/// `enabled`, `label`) e label opcional ao lado (8px de gap).
class KicksterToggle extends StatelessWidget {
  const KicksterToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.semanticsLabel,
  });

  /// Estado ligado/desligado.
  final bool value;

  /// Callback ao alternar. `null` desabilita o controle.
  final ValueChanged<bool>? onChanged;

  /// Rótulo visual exibido ao lado do toggle (opcional).
  final String? label;

  /// Rótulo lido por leitores de tela; quando ausente, usa [label].
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = semanticsLabel ?? label;
    final trackColor = value ? AppColors.primary : AppColors.toggleOff;

    final toggle = Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: effectiveLabel,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(1000),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                alignment: value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: trackColor, width: 2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (label == null) return toggle;

    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          toggle,
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