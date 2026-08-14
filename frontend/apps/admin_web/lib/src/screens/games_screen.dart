import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Gestão de jogos: lista por rodada e acesso ao formulário.
class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitions = ref.watch(competitionsProvider);
    final selectedCompetition = ref.watch(selectedCompetitionProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedRound = ref.watch(selectedRoundProvider);

    final compItems = competitions.valueOrNull ?? const [];
    final effectiveComp =
        selectedCompetition ?? (compItems.isNotEmpty ? compItems.first.id : null);
    final categories = effectiveComp == null
        ? null
        : ref.watch(categoriesProvider(effectiveComp));
    final catItems = categories?.valueOrNull ?? const [];
    final effectiveCat =
        selectedCategory ?? (catItems.isNotEmpty ? catItems.first.id : null);
    final rounds = effectiveCat == null
        ? null
        : ref.watch(roundsProvider(effectiveCat));
    final roundItems = rounds?.valueOrNull ?? const [];
    final effectiveRound =
        selectedRound ?? (roundItems.isNotEmpty ? roundItems.first.id : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Jogos')),
      floatingActionButton: effectiveRound == null
          ? null
          : FloatingActionButton(
              tooltip: 'Novo jogo',
              onPressed: () => context.push(
                '/games/new',
                extra: (categoryId: effectiveCat, roundId: effectiveRound, game: null),
              ),
              child: const Icon(Icons.add),
            ),
      body: competitions.when(
        loading: () => const AppLoading(message: 'Carregando campeonatos...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar os campeonatos',
          onRetry: () => ref.invalidate(competitionsProvider),
        ),
        data: (_) {
          if (compItems.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhum campeonato cadastrado',
              icon: Icons.emoji_events_outlined,
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: DropdownButtonFormField<String>(
                  initialValue: effectiveComp,
                  decoration: const InputDecoration(
                    labelText: 'Campeonato',
                    border: OutlineInputBorder(),
                  ),
                  items: compItems
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (value) {
                    ref.read(selectedCompetitionProvider.notifier).state = value;
                    ref.read(selectedCategoryProvider.notifier).state = null;
                    ref.read(selectedRoundProvider.notifier).state = null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: (categories?.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => const Text('Erro ao carregar categorias'),
                  data: (items) => DropdownButtonFormField<String>(
                    initialValue: effectiveCat,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: items
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (value) {
                      ref.read(selectedCategoryProvider.notifier).state = value;
                      ref.read(selectedRoundProvider.notifier).state = null;
                    },
                  ),
                ) ??
                const LinearProgressIndicator()),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: (rounds?.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => const Text('Erro ao carregar rodadas'),
                  data: (items) => DropdownButtonFormField<String>(
                    initialValue: effectiveRound,
                    decoration: const InputDecoration(
                      labelText: 'Rodada',
                      border: OutlineInputBorder(),
                    ),
                    items: items
                        .map((r) => DropdownMenuItem(
                              value: r.id,
                              child: Text('Rodada ${r.number} - ${r.name}'),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        ref.read(selectedRoundProvider.notifier).state = value,
                  ),
                ) ??
                const LinearProgressIndicator()),
              ),
              Expanded(
                child: effectiveRound == null
                    ? const AppEmptyState(
                        message: 'Nenhuma rodada cadastrada',
                        icon: Icons.format_list_numbered,
                      )
                    : ref.watch(gamesByRoundProvider(effectiveRound)).when(
                        loading: () => const AppLoading(message: 'Carregando jogos...'),
                        error: (error, stackTrace) => AppErrorState(
                          message: 'Não foi possível carregar os jogos',
                          onRetry: () =>
                              ref.invalidate(gamesByRoundProvider(effectiveRound)),
                        ),
                        data: (items) {
                          if (items.isEmpty) {
                            return const AppEmptyState(
                              message: 'Nenhum jogo cadastrado',
                              icon: Icons.sports,
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final game = items[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(
                                    '${game.homeTeamName ?? 'Casa'} x ${game.awayTeamName ?? 'Fora'}',
                                  ),
                                  subtitle: Text(
                                    '${_formatDateTime(game.scheduledAt)} · ${game.status.name}',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => context.push(
                                    '/games/${game.id}',
                                    extra: (
                                      categoryId: effectiveCat,
                                      roundId: game.roundId,
                                      game: game,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _formatDateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
