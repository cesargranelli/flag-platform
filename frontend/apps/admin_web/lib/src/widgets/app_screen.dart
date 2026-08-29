import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Item da trilha de navegação do [AppScreen] (issue #455).
///
/// Cada item representa um nível da hierarquia; o nível atual (a tela em
/// exibição) não entra na lista — o [AppScreen] usa o próprio
/// [AppScreen.title] como último nível da trilha. Itens com [route] são
/// clicáveis (cor `primary`, hover/foco) e navegam para a listagem do módulo;
/// itens sem [route] são exibidos como texto `textSecondary`.
class BreadcrumbItem {
  const BreadcrumbItem(this.label, {this.route});

  final String label;

  /// Rota da listagem do módulo (ex.: `/organizations`). Quando nula, o item
  /// vira texto estático (nível intermediário da hierarquia).
  final String? route;
}

/// Scaffold padrão das telas autenticadas do Admin Web (issue #457).
///
/// Padrão **shadcn sidebar-01**:
///
/// - **Sticky Header** (48px): breadcrumb (desktop: trilha `Módulo › Nome`,
///   mobile: back button `← Módulo`).
/// - **Page Body** (scrollável, padding 24px): conteúdo gerenciado pela tela.
///
/// O título, ações e conteúdo ficam sob responsabilidade de cada tela.
/// O [AppScreen] apenas fornece o container com breadcrumb sticky + padding.
class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.title,
    required this.body,
    this.breadcrumb,
  });

  final String title;

  /// Conteúdo principal da página.
  final Widget body;

  /// Trilha de navegação exibida no sticky header (issue #455).
  final List<BreadcrumbItem>? breadcrumb;

  @override
  Widget build(BuildContext context) {
    final crumbs = breadcrumb ?? const <BreadcrumbItem>[];
    final isWide = MediaQuery.sizeOf(context).width >= 960;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sticky header: breadcrumb only.
        _StickyHeader(crumbs: crumbs, isWide: isWide),
        // Page body: scrollável com padding 24px.
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: body,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky Header
// ---------------------------------------------------------------------------

/// Header sticky (48px) com breadcrumb.
///
/// - Desktop (>=960px): breadcrumb trail (`Módulo › Nome`) à esquerda.
/// - Mobile (<960px): back button (`← Módulo`) à esquerda.
class _StickyHeader extends StatelessWidget {
  const _StickyHeader({required this.crumbs, required this.isWide});

  final List<BreadcrumbItem> crumbs;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (crumbs.isNotEmpty)
            Expanded(
              child: isWide
                  ? _BreadcrumbTrail(crumbs: crumbs)
                  : _BackCrumb(
                      label: crumbs.first.label,
                      route: crumbs.first.route,
                    ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Breadcrumb components
// ---------------------------------------------------------------------------

/// Trilha de breadcrumb responsiva (issue #455): `Módulo › Nome` em desktop.
class _BreadcrumbTrail extends StatelessWidget {
  const _BreadcrumbTrail({required this.crumbs});

  final List<BreadcrumbItem> crumbs;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        for (var i = 0; i < crumbs.length; i++) ...[
          if (i > 0) _crumbSeparator(),
          _CrumbLink(label: crumbs[i].label, route: crumbs[i].route),
        ],
      ],
    );
  }

  static Widget _crumbSeparator() => const Text(
        '›',
        style: TextStyle(
          fontSize: 14,
          height: 1,
          color: AppColors.textSecondary,
        ),
      );
}

/// Navega para a listagem do módulo (breadcrumb/back).
void _goToListing(BuildContext context, String? route) {
  final target = route;
  if (target == null) return;
  context.go(target);
}

/// Link de nível do breadcrumb: texto 14px w500, cor `primary` quando
/// clicável (hover/foco com underline), `textSecondary` quando estático.
class _CrumbLink extends StatefulWidget {
  const _CrumbLink({required this.label, this.route});

  final String label;
  final String? route;

  @override
  State<_CrumbLink> createState() => _CrumbLinkState();
}

class _CrumbLinkState extends State<_CrumbLink> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final clickable = widget.route != null;
    return Focus(
      canRequestFocus: clickable,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: MouseRegion(
        cursor: clickable ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: clickable
              ? () => _goToListing(context, widget.route)
              : null,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              widget.label,
              style: _crumbTextStyle(clickable: clickable).copyWith(
                decoration: clickable && (_hovered || _focused)
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Back button do breadcrumb em viewports < 960px: `← Módulo` (issue #455).
class _BackCrumb extends StatelessWidget {
  const _BackCrumb({required this.label, this.route});

  final String label;
  final String? route;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: 'Voltar para $label',
        child: InkWell(
          onTap: route == null ? null : () => _goToListing(context, route),
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: Semantics(
              label: 'Voltar para $label',
              button: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(label, style: _crumbTextStyle(clickable: true)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Estilo dos níveis do breadcrumb: 14px w500 (padrão do kit).
TextStyle _crumbTextStyle({required bool clickable}) {
  return TextStyle(
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.07,
    color: clickable ? AppColors.primary : AppColors.textSecondary,
  );
}
