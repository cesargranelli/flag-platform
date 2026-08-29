import 'package:flutter/material.dart';

/// Scaffold padrão das telas autenticadas do Admin Web.
///
/// Com o shell global ([AdminShell]) assumindo o header (marca e chip de
/// usuário), o [AppScreen] ficou enxuto (issue #427): renderiza o título da
/// página como H1 (semântica `header`) + ações da tela (ex.: botão "Novo") e
/// o corpo. A navegação de voltar fica a cargo do navegador/brand do shell
/// (volta à home) — sem `leading`, sem AppBar duplicada e sem FAB (padrão
/// mobile substituído por botões web no cabeçalho).
class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  final String title;

  /// Ações da tela alinhadas à direita do título (ex.: "Novo").
  final List<Widget>? actions;

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (actions != null && actions!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    ...actions!,
                  ],
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}