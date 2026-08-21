import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Gestão de jogos: lista por rodada e acesso ao detalhe.
///
/// O fluxo agora é: campeonato → divisão → rodada → jogo.
/// As categories foram removidas; a associação competition→round
/// ocorre diretamente pela competition_id (migração V24).
class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitions = ref.watch(competitionsProvider);
    final selectedCompetition = ref.watch(selectedCompetitionProvider);
    final selectedRound = ref.watch(selectedRoundProvider);

    final compItems = competitions.valueOrNull ?? const [];
    final effectiveComp =
        selectedCompetition ??
        (compItems.isNotEmpty ? compItems.first.id : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jogos'),
        leading: BackButton(onPressed: () => context.go('/')),
        actions: [
          if (selectedRound != null)
            IconButton(
              tooltip: 'Importar CSV',
              icon: const Icon(Icons.upload_file),
              onPressed: () =>
                  context.push('/games/import', extra: selectedRound),
            ),
        ],
      ),
      floatingActionButton: effectiveComp != null
          ? FloatingActionButton(
              tooltip: 'Novo jogo',
              onPressed: () => context.push(
                '/games/new',
                extra: (
                  competitionId: effectiveComp,
                  roundId: selectedRound,
                  game: null,
                ),
              ),
              child: const Icon(Icons.add),
            )
          : null,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppLayout.content(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey('comp-$effectiveComp'),
                        initialValue: effectiveComp,
                        decoration: const InputDecoration(
                          labelText: 'Campeonato',
                          border: OutlineInputBorder(),
                        ),
                        items: compItems
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          ref.read(selectedCompetitionProvider.notifier).state =
                              value;
                          ref.read(selectedRoundProvider.notifier).state = null;
                        },
                      ),
                      const SizedBox(height: 12),
                      (effectiveComp != null)
                          ? ref
                                .watch(roundsProvider(effectiveComp))
                                .when(
                                  loading: () =>
                                      const LinearProgressIndicator(),
                                  error: (e, s) => AppErrorState(
                                    message:
                                        'Não foi possível carregar as rodadas',
                                    onRetry: () => ref.invalidate(
                                      roundsProvider(effectiveComp),
                                    ),
                                  ),
                                  data: (roundItems) =>
                                      DropdownButtonFormField<String>(
                                        key: ValueKey('round-$effectiveComp'),
                                        initialValue:
                                            selectedRound ??
                                            roundItems.first.id,
                                        decoration: const InputDecoration(
                                          labelText: 'Rodada',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: roundItems
                                            .map(
                                              (r) => DropdownMenuItem(
                                                value: r.id,
                                                child: Text(
                                                  'Rodada ${r.number} - ${r.name}',
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) =>
                                            ref
                                                    .read(
                                                      selectedRoundProvider
                                                          .notifier,
                                                    )
                                                    .state =
                                                value,
                                      ),
                                )
                          : const LinearProgressIndicator(),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: selectedRound == null
                    ? const AppEmptyState(
                        message: 'Nenhuma rodada cadastrada',
                        icon: Icons.format_list_numbered,
                      )
                    : ref
                          .watch(gamesByRoundProvider(selectedRound))
                          .when(
                            loading: () => const AppLoading(
                              message: 'Carregando jogos...',
                            ),
                            error: (error, stackTrace) => AppErrorState(
                              message: 'Não foi possível carregar os jogos',
                              onRetry: () => ref.invalidate(
                                gamesByRoundProvider(selectedRound),
                              ),
                            ),
                            data: (items) {
                              if (items.isEmpty) {
                                return const AppEmptyState(
                                  message: 'Nenhum jogo cadastrado',
                                  icon: Icons.sports,
                                );
                              }
                              return AppLayout.content(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final columns = constraints.maxWidth >= 600
                                        ? 2
                                        : 1;
                                    return GridView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: items.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: columns,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            mainAxisExtent: 104,
                                          ),
                                      itemBuilder: (context, index) {
                                        final game = items[index];
                                        return _gameCard(
                                          context,
                                          game,
                                          onTap: () => context.push(
                                            '/games/${game.id}',
                                            extra: (
                                              competitionId: effectiveComp,
                                              roundId: game.roundId,
                                              game: game,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
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

  Widget _gameCard(
    BuildContext context,
    Game game, {
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${game.homeTeamName ?? 'Casa'} x ${game.awayTeamName ?? 'Fora'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusChip(game.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatDateTime(game.scheduledAt)}'
                '${game.venueName != null ? ' · ${game.venueName}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              if (game.homeScore != null || game.awayScore != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Placar: ${game.homeScore ?? 0} x ${game.awayScore ?? 0}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(GameStatus status) {
    final (label, color) = switch (status) {
      GameStatus.scheduled => ('Agendado', AppColors.textSecondary),
      GameStatus.inProgress => ('Ao vivo', AppColors.success),
      GameStatus.finished => ('Encerrado', AppColors.danger),
      GameStatus.cancelled => ('Cancelado', AppColors.disabled),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color)),
    );
  }
}

String _formatDateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
