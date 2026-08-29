import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Breadcrumb no padrão shadcn/ui adaptado ao design Kickster.
///
/// Composição:
/// ```dart
/// KicksterBreadcrumb(
///   items: [
///     KicksterBreadcrumbItem(label: 'Home', route: '/'),
///     KicksterBreadcrumbItem(label: 'Competições', route: '/competitions'),
///     KicksterBreadcrumbItem(label: 'Copa América 2026'),
///   ],
/// )
/// ```
///
/// Comportamento:
/// - ≤ [maxVisible] itens: mostra todos com separadores chevron
/// - > [maxVisible] itens: mostra primeiro + ellipsis + últimos 2
/// - Mobile (< 960px): exibe apenas botão voltar com label do nível pai
class KicksterBreadcrumb extends StatelessWidget {
  const KicksterBreadcrumb({
    super.key,
    required this.items,
    this.maxVisible = 3,
  });

  /// Lista de itens do breadcrumb.
  final List<KicksterBreadcrumbItem> items;

  /// Número máximo de itens visíveis antes de colapsar com ellipsis.
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isWide = MediaQuery.sizeOf(context).width >= 960;

    return Container(
      height: isWide ? 40 : 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border(
          bottom: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      child: isWide
          ? _DesktopBreadcrumb(items: items, maxVisible: maxVisible)
          : _MobileBackButton(item: items.first),
    );
  }
}

/// Item individual do breadcrumb.
class KicksterBreadcrumbItem {
  const KicksterBreadcrumbItem({
    required this.label,
    this.route,
    this.icon,
  });

  /// Texto exibido para o item.
  final String label;

  /// Rota de navegação. Se nula, é a página atual (não clicável).
  final String? route;

  /// Ícone opcional antes do texto (ex: home_outlined).
  final IconData? icon;
}

// ---------------------------------------------------------------------------
// Desktop breadcrumb (trail completa)
// ---------------------------------------------------------------------------

class _DesktopBreadcrumb extends StatelessWidget {
  const _DesktopBreadcrumb({
    required this.items,
    required this.maxVisible,
  });

  final List<KicksterBreadcrumbItem> items;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final shouldCollapse = items.length > maxVisible;

    if (!shouldCollapse) {
      return Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const _ChevronSeparator(),
            _BreadcrumbItemWidget(item: items[i]),
          ],
        ],
      );
    }

    // Colapsado: primeiro + ellipsis + últimos 2
    final first = items.first;
    final lastTwo = items.skip(items.length - 2).toList();
    final hiddenCount = items.length - 3;

    return Row(
      children: [
        _BreadcrumbItemWidget(item: first),
        const _ChevronSeparator(),
        _EllipsisItem(hiddenCount: hiddenCount),
        const _ChevronSeparator(),
        for (var i = 0; i < lastTwo.length; i++) ...[
          if (i > 0) const _ChevronSeparator(),
          _BreadcrumbItemWidget(item: lastTwo[i]),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile back button
// ---------------------------------------------------------------------------

class _MobileBackButton extends StatelessWidget {
  const _MobileBackButton({required this.item});

  final KicksterBreadcrumbItem item;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: item.route != null ? () => context.go(item.route!) : null,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_back,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 14,
                  height: 22 / 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Item widget (link ou página atual)
// ---------------------------------------------------------------------------

class _BreadcrumbItemWidget extends StatefulWidget {
  const _BreadcrumbItemWidget({required this.item});

  final KicksterBreadcrumbItem item;

  @override
  State<_BreadcrumbItemWidget> createState() => _BreadcrumbItemWidgetState();
}

class _BreadcrumbItemWidgetState extends State<_BreadcrumbItemWidget> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isCurrent = item.route == null;

    if (isCurrent) {
      // Página atual: texto w600, não clicável
      return Semantics(
        child: Text(
          item.label,
          style: const TextStyle(
            fontSize: 14,
            height: 22 / 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      );
    }

    // Link clicável com hover background
    return Focus(
      canRequestFocus: true,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => context.go(item.route!),
          child: Tooltip(
            message: item.label,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _hovered || _focused
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.icon != null) ...[
                    Icon(
                      item.icon,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      height: 22 / 14,
                      fontWeight: FontWeight.w500,
                      color: _hovered || _focused
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      decoration: _hovered
                          ? TextDecoration.underline
                          : null,
                      decorationColor: AppColors.primary,
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

// ---------------------------------------------------------------------------
// Separador chevron
// ---------------------------------------------------------------------------

class _ChevronSeparator extends StatelessWidget {
  const _ChevronSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.chevron_right,
        size: 14,
        color: AppColors.textSecondary,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ellipsis (itens ocultos)
// ---------------------------------------------------------------------------

class _EllipsisItem extends StatelessWidget {
  const _EllipsisItem({required this.hiddenCount});

  final int hiddenCount;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$hiddenCount nível(is) oculto(s)',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '…',
          style: TextStyle(
            fontSize: 16,
            height: 20 / 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
