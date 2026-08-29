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

/// Scaffold padrão das telas autenticadas do Admin Web.
///
/// Com o shell global ([AdminShell]) assumindo o header/marca, o [AppScreen]
/// renderiza (issue #457):
///
/// - **Breadcrumb** opcional (trilha `Módulo › Nome` em desktop, back button
///   `← Módulo` em mobile).
/// - **Toolbar** com título da página (18px w600) + ações à direita (ex.:
///   botão "Novo").
/// - **Body** (conteúdo principal).
///
/// O título não é mais um H1 gigante — o padrão de painéis coloca o contexto
/// de navegação na sidebar/header e usa o título como seção (18px w600).
class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.breadcrumb,
    this.showBreadcrumb = true,
  });

  final String title;

  /// Ações da tela alinhadas à direita do título (ex.: "Novo").
  final List<Widget>? actions;

  final Widget body;

  /// Trilha de navegação exibida acima do título (issue #455).
  ///
/// Em viewports `>=960px` vira a trilha `Módulo › Nome` — o primeiro nível
  /// (clicável, hover/foco) navega para a listagem do módulo e o título da
  /// tela fecha a trilha como nível atual. Abaixo de 960px vira o back button
  /// `← Módulo`, que também retorna à listagem.
  final List<BreadcrumbItem>? breadcrumb;

  /// Controla a exibição do breadcrumb quando [breadcrumb] é informado.
  final bool showBreadcrumb;

  /// Itens efetivamente exibidos (respeita [showBreadcrumb]).
  List<BreadcrumbItem> get _crumbs {
    if (!showBreadcrumb) return const <BreadcrumbItem>[];
    return breadcrumb ?? const <BreadcrumbItem>[];
  }

  @override
  Widget build(BuildContext context) {
    final crumbs = _crumbs;
    final isWide = MediaQuery.sizeOf(context).width >= 960;
    final showMobileBack = !isWide && crumbs.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Breadcrumb: trilha completa (desktop) ou back button (mobile).
            if (crumbs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: isWide
                    ? _BreadcrumbTrail(crumbs: crumbs)
                    : _BackCrumb(
                        label: crumbs.first.label,
                        route: crumbs.first.route,
                      ),
              ),

            // Toolbar: título (18px w600) + ações à direita.
            if (actions != null && actions!.isNotEmpty || !showMobileBack)
              _Toolbar(
                title: title,
                showTitle: true,
                actions: actions,
              ),

            // Bug #1: espaçamento top quando não há breadcrumb para evitar
            // conteúdo colado ao topo do SafeArea.
            if (crumbs.isEmpty) const SizedBox(height: 24),

            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// Toolbar com título e ações.
///
/// O título aparece quando não há breadcrumb (ou em mobile com back button)
/// para dar contexto à página. Ações ficam à direita com `Spacer`.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.title,
    required this.showTitle,
    this.actions,
  });

  final String title;
  final bool showTitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final hasActions = actions != null && actions!.isNotEmpty;
    if (!showTitle && !hasActions) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: hasActions
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.line, width: 1),
              ),
            )
          : null,
      child: Row(
        children: [
          if (showTitle)
            Semantics(
              header: true,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (showTitle && hasActions) const Spacer(),
          if (hasActions) ...actions!,
        ],
      ),
    );
  }
}

/// Trilha de breadcrumb responsiva (issue #455): `Módulo › Nome` em desktop.
///
/// Os itens da lista são os níveis acima; o título da página (já exibido no
/// [_Toolbar]) é implícito como nível final da trilha.
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
///
/// Usa `context.go` — o breadcrumb é a trilha explícita da hierarquia e
/// deve pousar sempre na listagem, independente de onde o usuário veio
/// (o browser back continua preservado pela navegação `push` das listagens).
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
          onTap: route == null
              ? null
              : () => _goToListing(context, route),
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
