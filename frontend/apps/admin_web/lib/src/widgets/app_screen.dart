import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Variação tipográfica do H1 das telas ([AppScreen.titleVariant]).
///
/// `headline` = `headlineMedium` (40/48) — padrão das telas de detalhe, onde
/// o título carrega o nome da entidade; `titleLg` = `title.lg` (24/32) —
/// usado nas listagens de gestão (issue #449), onde um H1 gigante disputa
/// atenção com os cards.
enum AppScreenTitleVariant { headline, titleLg }

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
/// Com o shell global ([AdminShell]) assumindo o header (marca + chip de
/// usuário), o [AppScreen] ficou enxuto (issue #427): renderiza o breadcrumb
/// opcional (issue #455), o título da página como H1 (semântica `header`) +
/// ações da tela (ex.: botão "Novo") e o corpo. A navegação de voltar fica a
/// cargo do navegador — sem `leading`, sem AppBar duplicada (issue #451) e
/// sem FAB (padrão mobile substituído por botões web no cabeçalho).
///
/// O título das telas de detalhe/edição/criação (variante `headline`) segue o
/// grid de leitura ([AppLayout.detail], 720px), como quando havia o link de
/// voltar; as listagens (variante `titleLg`) usam a largura total.
class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.titleVariant = AppScreenTitleVariant.headline,
    this.breadcrumb,
    this.showBreadcrumb = true,
  });

  final String title;

  /// Variação tipográfica do H1 (issue #449): listagens usam `titleLg` para
  /// reduzir a escala (24/32); detalhes mantêm o `headline` (40/48).
  final AppScreenTitleVariant titleVariant;

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
    // Telas de detalhe/edição/criação (`headline`) alinham o título ao grid
    // de leitura (720px); listagens (`titleLg`) usam a largura total.
    final alignToDetailGrid =
        titleVariant == AppScreenTitleVariant.headline;
    final crumbs = _crumbs;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (crumbs.isNotEmpty) ...[
                    if (alignToDetailGrid)
                      AppLayout.detail(child: _breadcrumb(context, crumbs))
                    else
                      _breadcrumb(context, crumbs),
                    const SizedBox(height: 10),
                  ],
                  if (alignToDetailGrid)
                    AppLayout.detail(child: _titleRow(context))
                  else
                    _titleRow(context),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _titleRow(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final baseStyle = switch (titleVariant) {
      AppScreenTitleVariant.headline => textTheme.headlineMedium,
      AppScreenTitleVariant.titleLg => textTheme.titleLarge,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Semantics(
            header: true,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: baseStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (actions != null && actions!.isNotEmpty) ...[
          const SizedBox(width: 12),
          ...actions!,
        ],
      ],
    );
  }

  /// Breadcrumb responsivo (issue #455): trilha `Módulo › Nome` em telas
  /// largas; back button `← Módulo` abaixo de 960px.
  Widget _breadcrumb(BuildContext context, List<BreadcrumbItem> crumbs) {
    if (MediaQuery.sizeOf(context).width < 960) {
      return _BackCrumb(
        label: crumbs.first.label,
        route: crumbs.first.route,
      );
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        for (var i = 0; i < crumbs.length; i++) ...[
          if (i > 0) _crumbSeparator(),
          _CrumbLink(label: crumbs[i].label, route: crumbs[i].route),
        ],
        _crumbSeparator(),
        Text(
          title,
          style: _crumbTextStyle(clickable: false),
        ),
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

  /// Navega para a listagem do módulo (breadcrumb/back).
  ///
  /// Usa `context.go` — o breadcrumb é a trilha explícita da hierarquia e
  /// deve pousar sempre na listagem, independente de onde o usuário veio
  /// (o browser back continua preservado pela navegação `push` das listagens).
  static void _goToListing(BuildContext context, String? route) {
    final target = route;
    if (target == null) return;
    context.go(target);
  }
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
              ? () => AppScreen._goToListing(context, widget.route)
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
              : () => AppScreen._goToListing(context, route),
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