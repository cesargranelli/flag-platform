import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/competition_card.dart';

/// Tela inicial do Public App: lista de campeonatos.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitions = ref.watch(competitionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Campeonatos')),
      body: competitions.when(
        loading: () => const AppLoading(message: 'Carregando campeonatos...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar os campeonatos',
          onRetry: () => ref.invalidate(competitionsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhum campeonato disponível',
              icon: Icons.sports_football,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final competition = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CompetitionCard(
                  competition: competition,
                  // Definiu-se o "campeonato em foco" e navega para a aba
                  // Campeonato (issue #389). O `go` troca de aba/página
                  // enquanto o `push` empilharia sobre a barra inferior.
                  onTap: () {
                    ref.read(focusedCompetitionProvider.notifier).set(
                      (id: competition.id, name: competition.name),
                    );
                    context.go('/competition/${competition.id}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
