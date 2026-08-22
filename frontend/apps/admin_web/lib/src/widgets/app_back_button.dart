import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Botão de voltar resiliente para o Admin Web.
///
/// Faz `Navigator.pop` quando há pilha de navegação (fluxo normal de
/// detalhe/edição via `push`). Em deep link/refresh (sem pilha no GoRouter),
/// navega para a [fallbackRoute] para o usuário não ficar preso na tela.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.fallbackRoute});

  /// Rota de fallback quando não há pilha de navegação (ex.: lista do módulo).
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    // Caixa 40×40: reduz o círculo de hover/ripple do IconButton padrão
    // (48×48), mantendo alvo de toque acessível e efeito consistente.
    return SizedBox(
      width: 40,
      height: 40,
      child: BackButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(fallbackRoute);
          }
        },
      ),
    );
  }
}
