import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Scaffold padrão das telas autenticadas do Admin Web.
///
/// Com o shell global ([AdminShell]) assumindo o header (marca e chip de
/// usuário), o [AppScreen] ficou enxuto (issue #427): renderiza o título da
/// página como H1 (semântica `header`) + ações da tela (ex.: botão "Novo") e
/// o corpo. A navegação de voltar fica a cargo do navegador/brand do shell
/// (volta à home) — sem `leading`, sem AppBar duplicada e sem FAB (padrão
/// mobile substituído por botões web no cabeçalho).
///
/// Telas de detalhe/edição/criação podem informar [backTarget] (+ [backLabel])
/// para exibir um link de voltar hierárquico ([AppBackLink], issue #435)
/// acima do título: o destino é derivado da rota e aplicado via
/// `context.go` (o admin_web usa URL substituída, sem pilha). [onBack]
/// customizado tem prioridade sobre o `context.go` padrão.
class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.backTarget,
    this.backLabel,
    this.onBack,
  });

  final String title;

  /// Ações da tela alinhadas à direita do título (ex.: "Novo").
  final List<Widget>? actions;

  final Widget body;

  /// Rota de destino do link de voltar hierárquico (issue #435).
  ///
  /// Quando não nulo, renderiza um [AppBackLink] acima do título (H1),
  /// alinhado à esquerda. Listas não informam — a marca do shell volta à home.
  final String? backTarget;

  /// Rótulo contextual do link de voltar (ex.: "Organizações"). Quando nulo,
  /// o [AppBackLink] usa `AppStrings.back` ('Voltar').
  final String? backLabel;

  /// Callback custom de voltar — tem prioridade sobre `context.go(backTarget)`.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (backTarget != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppBackLink(
                    label: backLabel,
                    onPressed:
                        onBack ?? () => context.go(backTarget!),
                  ),
                ),
              ),
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