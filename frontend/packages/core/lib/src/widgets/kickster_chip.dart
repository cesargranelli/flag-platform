import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Chip selecionável no estilo do kit Kickster (issue #436).
///
/// Mesmo padrão do `SelectableChip` (#290/#292/#300): raio 10, sem bordas,
/// estado por preenchimento — não selecionado = fundo `grayFill` + texto
/// `textPrimary`; **selecionado** = fundo `primary` + conteúdo BRANCO
/// (#294). Interação via `InkWell` padrão do tema (sem splash customizado),
/// altura compacta ~34px (padding 16×8) como os chips atuais.
class KicksterChip extends StatelessWidget {
  const KicksterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.textPrimary;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.grayFill,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTextStyles.footerLink.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}