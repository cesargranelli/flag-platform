import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Tela inicial do Referee App (painel da mesa).
class RefereeHomeScreen extends ConsumerWidget {
  const RefereeHomeScreen({super.key});

  /// Confirma o logout antes de encerrar a sessão (padrão admin_web,
  /// issue #425#14).
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final userName = auth.state.user?.name;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flag Referee App'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_score, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Bem-vindo, ${userName ?? 'mesa'}!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Operar partida'),
                    onPressed: () => context.push('/operation'),
                  ),
                  // A conferência de atletas é acessada pela operação, somente
                  // quando a partida estiver aberta (OPEN) — issue #490.
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}