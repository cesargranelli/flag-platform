import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Breadcrumb no padrão shadcn/ui adaptado ao design Kickster.
///
/// Renderiza inline (sem container separado), exatamente como o shadcn:
/// `Home › ... › Components › **Breadcrumb**`
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
class KicksterBreadcrumb extends StatelessWidget {
  const KicksterBreadcrumb({
    super.key,
    required this.items,
    this.maxVisible = 3,
  });

  final List<KicksterBreadcrumbItem> items;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isWide = MediaQuery.sizeOf(context).width >= 960;

    if (!isWide) {
      // Botão voltar: navega para o ÚLTIMO item com rota (a listagem do
      // módulo, ex.: /organizations) em vez de sempre o primeiro ("Início") —
      // o primeiro item é a home, não a origem da navegação (#457).
      KicksterBreadcrumbItem? backItem;
      for (final item in items.reversed) {
        if (item.route != null) {
          backItem = item;
          break;
        }
      }
      if (backItem == null) return const SizedBox.shrink();
      return _MobileBackButton(item: backItem);
    }

    final shouldCollapse = items.length > maxVisible;

    if (!shouldCollapse) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 0,
        runSpacing: 4,
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

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: 4,
      children: [
        _BreadcrumbItemWidget(item: first),
        const _ChevronSeparator(),
        const _EllipsisItem(),
        const _ChevronSeparator(),
        for (var i = 0; i < lastTwo.length; i++) ...[
          if (i > 0) const _ChevronSeparator(),
          _BreadcrumbItemWidget(item: lastTwo[i]),
        ],
      ],
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

  final String label;
  final String? route;
  final IconData? icon;
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
      child: Semantics(
        button: true,
        label: 'Voltar para ${item.label}',
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

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isCurrent = item.route == null;

    // Página atual: bold, sem link
    if (isCurrent) {
      return Text(
        item.label,
        style: const TextStyle(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );
    }

    // Link clicável: InkWell (hover + foco por Tab + ativação via Enter +
    // Semantics de botão/link de graça), mantendo o texto com hover primary
    // e o cursor de click.
    return Semantics(
      button: true,
      link: true,
      label: item.label,
      child: InkWell(
        onTap: () => context.go(item.route!),
        onHover: (v) => setState(() => _hovered = v),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Text(
            item.label,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w400,
              color: _hovered ? AppColors.primary : AppColors.textSecondary,
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
      padding: EdgeInsets.symmetric(horizontal: 6),
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
  const _EllipsisItem();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '…',
      style: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
    );
  }
}
