import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';

/// Variação tipográfica do H1 das telas ([AppScreen.titleVariant]).
///
/// `headline` = `headlineMedium` (40/48) — padrão das telas de detalhe, onde
/// o título carrega o nome da entidade; `titleLg` = `title.lg` (24/32) —
/// usado nas listagens de gestão (issue #449), onde um H1 gigante disputa
/// atenção com os cards.
enum AppScreenTitleVariant { headline, titleLg }

/// Scaffold padrão das telas autenticadas do Admin Web.
///
/// Com o shell global ([AdminShell]) assumindo o header (chip de usuário), o
/// [AppScreen] ficou enxuto (issue #427): renderiza o título da página como
/// H1 (semântica `header`) + ações da tela (ex.: botão "Novo") e o corpo. A
/// navegação de voltar fica a cargo do navegador — sem `leading`, sem AppBar
/// duplicada, sem links de voltar hierárquicos (issue #451) e sem FAB
/// (padrão mobile substituído por botões web no cabeçalho).
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
  });

  final String title;

  /// Variação tipográfica do H1 (issue #449): listagens usam `titleLg` para
  /// reduzir a escala (24/32); detalhes mantêm o `headline` (40/48).
  final AppScreenTitleVariant titleVariant;

  /// Ações da tela alinhadas à direita do título (ex.: "Novo").
  final List<Widget>? actions;

  final Widget body;

  @override
  Widget build(BuildContext context) {
    // Telas de detalhe/edição/criação (`headline`) alinham o título ao grid
    // de leitura (720px); listagens (`titleLg`) usam a largura total.
    final alignToDetailGrid =
        titleVariant == AppScreenTitleVariant.headline;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: alignToDetailGrid
                  ? AppLayout.detail(child: _titleRow(context))
                  : _titleRow(context),
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
}
