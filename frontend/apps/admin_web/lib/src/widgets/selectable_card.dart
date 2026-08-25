import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';

/// Card selecionável do design system (issues #287/#290).
///
/// Segue o padrão de [Card] do app: `surface`, raio 16 (`radius.card`) e
/// elevação 1 (`elevation.card`) — sem borda permanente; os contornos
/// aparecem apenas em estados específicos (foco e seleção), como anel em
/// `foregroundDecoration` para não deslocar o conteúdo.
///
/// Estados: padrão (card puro) · hover (tinta `gray.fill`) · foco
/// (contorno `primary` 2px) · selecionado (contorno `primary` 2px +
/// tinta `primary` @10% + badge de check) · desabilitado (55% opacidade).
///
/// Regra de contraste: conteúdo sobre o preenchimento `primary` usa
/// `AppColors.black` (branco sobre #FD6B22 reprova WCAG AA).
class SelectableCard extends StatefulWidget {
  const SelectableCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
    this.icon,
    this.enabled = true,
    this.minHeight = 96,
  });

  final String label;
  final String? description;
  final IconData? icon;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final double minHeight;

  @override
  State<SelectableCard> createState() => _SelectableCardState();
}

class _SelectableCardState extends State<SelectableCard> {
  static const _radius = BorderRadius.all(Radius.circular(16));

  /// Foco rastreado para desenhar o contorno de foco (`primary` 2px),
  /// mesmo tratamento visual de foco aplicado aos inputs do tema.
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(SelectableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Desabilitado não retém foco (evita estado preso sem ação associada).
    if (!widget.enabled && _focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  /// Anel de estado (foco/seleção) desenhado sobre o card, sem afetar
  /// o layout — evita jitter de 1px entre estados.
  BoxDecoration? _stateRing() {
    if (!widget.selected && !_focusNode.hasFocus) return null;
    return BoxDecoration(
      borderRadius: _radius,
      border: Border.all(color: AppColors.primary, width: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.enabled ? 1 : 0.55,
      child: Semantics(
        selected: widget.selected,
        enabled: widget.enabled,
        child: Material(
          // Selecionado mantém a tinta primary @10%; padrão é card surface
          // elevação 1, igual ao Card usado nas demais telas do app.
          color: widget.selected
              ? AppColors.primary.withValues(alpha: 0.10)
              : AppColors.surface,
          elevation: 1,
          borderRadius: _radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.enabled ? widget.onTap : null,
            focusNode: _focusNode,
            canRequestFocus: widget.enabled,
            borderRadius: _radius,
            hoverColor: AppColors.grayFill,
            focusColor: AppColors.primary.withValues(alpha: 0.18),
            child: Container(
              constraints:
                  BoxConstraints(minHeight: widget.minHeight),
              padding: const EdgeInsets.all(16),
              foregroundDecoration: _stateRing(),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 28,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        widget.label,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (widget.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.description!,
                          style: AppTextStyles.footerLink
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                  if (widget.selected)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: ExcludeSemantics(
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.black,
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
/// Métricas estáveis entre estados (borda sempre 1px, peso fixo) para
/// evitar jitter no wrap: raio 10 (`radius.chip`), altura ~34px, tipografia
/// 13/17 (`footerLink`). Não selecionado: fundo `surface` + borda `black`.
/// Selecionado: fundo `primary` + texto `black` (contraste WCAG AA).
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
        hoverColor: AppColors.grayFill,
        focusColor: AppColors.primary.withValues(alpha: 0.18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.black,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.footerLink.copyWith(
              color: selected ? AppColors.black : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
