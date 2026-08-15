import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Gestão de campeonatos: lista e acesso ao formulário de criação/edição.
class CompetitionsScreen extends ConsumerWidget {
  const CompetitionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitions = ref.watch(competitionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campeonatos'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo campeonato',
        onPressed: () => context.push('/competitions/new'),
        child: const Icon(Icons.add),
      ),
      body: competitions.when(
        loading: () => const AppLoading(message: 'Carregando campeonatos...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar os campeonatos',
          onRetry: () => ref.invalidate(competitionsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhum campeonato cadastrado',
              icon: Icons.emoji_events_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final competition = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(competition.name),
                  subtitle: Text(competition.organizationName ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    '/competitions/${competition.id}',
                    extra: competition,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
