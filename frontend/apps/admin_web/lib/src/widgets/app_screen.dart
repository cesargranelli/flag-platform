import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Scaffold padrão do Admin Web com navbar global.
///
/// Toda tela autenticada usa este wrapper: AppBar com título, leading
/// opcional e actions da tela, seguidos SEMPRE do nome do usuário e do
/// botão sair (com confirmação). Telas pré-autenticação (login, signup,
/// recuperação de senha) não o utilizam.
class AppScreen extends ConsumerWidget {
  const AppScreen({
    super.key,
    required this.title,
    required this.body,
    this.leading,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final userName = auth.state.user?.name;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: leading,
        actions: [
          ...?actions,
          if (auth.state.authenticated) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  userName ?? 'organizador',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Sair',
              icon: const Icon(Icons.logout_outlined),
              onPressed: () => _confirmLogout(context, ref),
            ),
          ],
        ],
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final logout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente encerrar a sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (logout == true) {
      // O GoRouter observa o AuthController e redireciona para /login.
      ref.read(authControllerProvider.notifier).logout();
    }
  }
}
