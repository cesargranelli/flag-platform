import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';

/// Card selecionável do design system (issues #287/#290).
///
/// Segue o padrão de [Card] do app: `surface`, raio 16 (`radius.card`) e
/// elevação 1 (`elevation.card`) — sem borda permanente; os contornos
/// aparecem apenas em estados específicos (foco e seleção), como anel em
/// `foregroundDecoration` para não deslocar o conteúdo.
///
/// Estados: padrão (card puro) · hover (tinta suave) · foco
/// (contorno `primary` 2px) · selecionado (fundo `primary` sólido +
/// conteúdo branco + badge invertido) · desabilitado (55% opacidade).
///
/// Issue #294: decisão do produto — conteúdo sobre preenchimento
/// `primary` usa BRANCO.
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
          // Issue #294: selecionado = preenchimento primary SÓLIDO com
          // conteúdo branco; padrão é card surface elevação 1.
          color: widget.selected ? AppColors.primary : AppColors.surface,
          elevation: 1,
          borderRadius: _radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.enabled ? widget.onTap : null,
            focusNode: _focusNode,
            canRequestFocus: widget.enabled,
            borderRadius: _radius,
            hoverColor: widget.selected
                ? Colors.white.withValues(alpha: 0.10)
                : AppColors.grayFill,
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
                          color: widget.selected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        widget.label,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: widget.selected
                                      ? Colors.white
                                      : null,
                                ),
                      ),
                      if (widget.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.description!,
                          style: AppTextStyles.footerLink.copyWith(
                            color: widget.selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
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
/// Padrão SEM bordas (issue #292): o estado é comunicado por preenchimento.
/// Não selecionado: fundo `gray.fill` + texto `textPrimary`. Selecionado:
/// fundo `primary` + texto BRANCO (issue #294, decisão do produto).
/// Métricas estáveis entre estados para evitar jitter no wrap: raio 10
/// (`radius.chip`), altura ~34px, tipografia 13/17 (`footerLink`). Anel de
/// foco `primary` apenas na navegação por teclado (acessibilidade).
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
      child: Focus(
        canRequestFocus: onTap != null,
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              hoverColor: selected
                  ? Colors.white.withValues(alpha: 0.10)
                  : AppColors.grayFill,
              focusColor: Colors.transparent,
              child: Container(
                // Sem bordas em nenhum estado; foco por teclado usa anel
                // externo desenhado sobre o chip, sem afetar o layout.
                foregroundDecoration: focused
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      )
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selected ? AppColors.primary : AppColors.grayFill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    label,
                    style: AppTextStyles.footerLink.copyWith(
                      color:
                          selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
