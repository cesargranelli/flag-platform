import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Tela inicial do Referee App (painel da mesa).
class RefereeHomeScreen extends ConsumerWidget {
  const RefereeHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final userName = auth.state.user?.name;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Referee App'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_score, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Bem-vindo, ${userName ?? 'mesa'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Operar partida'),
              onPressed: () => context.push('/operation'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.how_to_reg),
              label: const Text('Check-in de atletas'),
              onPressed: () => context.push('/checkin'),
            ),
          ],
        ),
      ),
    );
  }
}
