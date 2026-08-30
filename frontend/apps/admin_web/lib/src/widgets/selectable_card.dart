import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';

/// Card selecionável do design system (issues #287/#290–#300).
///
/// Mesmo padrão de interação dos cards de lista (ex. lista de
/// campeonatos): [Card] + [InkWell] com a tinta padrão do tema — sem
/// hover/splash customizados, que causam cintilação no web (#300).
/// A seleção é comunicada por um `Container` interno com preenchimento:
/// não selecionado = card `surface` padrão; selecionado = fundo
/// `primary` sólido com conteúdo BRANCO e badge invertido (#294).
class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
    this.icon,
    this.enabled = true,
    this.minHeight = 120,
  });

  final String label;
  final String? description;
  final IconData? icon;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Semantics(
        selected: selected,
        enabled: enabled,
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: Container(
              constraints: BoxConstraints(minHeight: minHeight),
              padding: const EdgeInsets.all(16),
              color: selected ? AppColors.primary : null,
              child: Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 28,
                          color:
                              selected ? Colors.white : AppColors.textPrimary,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        label,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(color: selected ? Colors.white : null),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.footerLink.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (selected)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: ExcludeSemantics(
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip selecionável para grupos com muitas opções (ex.: faixa etária).
///
/// Padrão SEM bordas (#292), estado por preenchimento: não selecionado =
/// fundo `gray.fill` + texto `textPrimary`; selecionado = fundo
/// `primary` + texto BRANCO (#294). Interação idêntica aos cards de
/// lista: `InkWell` padrão do tema (#300).
class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
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
          child: Text(
            label,
            style: AppTextStyles.footerLink.copyWith(
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
