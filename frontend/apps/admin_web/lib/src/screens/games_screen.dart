import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../widgets/app_screen.dart';
import '../widgets/edit_restriction_note.dart';

/// Gestão de jogos: lista por rodada e acesso ao detalhe.
///
/// O fluxo agora é: campeonato → divisão → rodada → jogo.
/// As categories foram removidas; a associação competition→round
/// ocorre diretamente pela competition_id (migração V24).
class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);
    final selectedCompetition = ref.watch(selectedCompetitionProvider);
    final selectedRound = ref.watch(selectedRoundProvider);

    final compItems = competitions.valueOrNull ?? const [];
    final effectiveComp =
        selectedCompetition ??
        (compItems.isNotEmpty ? compItems.first.id : null);

    // Issue #261: criação/edição de jogos (incluída a importação CSV)
    // exige ser criador do campeonato ou ADMIN.
    final selectedCompetitionObj = compItems
        .where((c) => c.id == effectiveComp)
        .firstOrNull;
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider).state.user,
      selectedCompetitionObj,
    );

    return AppScreen(
      title: 'Jogos',
      actions: [
        if (selectedRound != null && canEdit)
          KicksterButton(
            label: 'Importar',
            icon: Icons.upload_file,
            variant: KicksterButtonVariant.outline,
            onPressed: () =>
                context.push('/games/import', extra: selectedRound),
          ),
        if (effectiveComp != null && canEdit)
          KicksterButton(
            label: 'Novo',
            icon: Icons.add,
            onPressed: () => context.go(
              '/games/new',
              extra: (
                competitionId: effectiveComp,
                roundId: selectedRound,
                game: null,
              ),
            ),
          ),
      ],
      body: competitions.when(
        loading: () => const AppLoading(message: 'Carregando campeonatos...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar os campeonatos',
          onRetry: () => ref.invalidate(competitionsProvider),
        ),
        data: (_) {
          if (compItems.isEmpty) {
            return KicksterEmptyState(
              icon: Icons.emoji_events_outlined,
              message: 'Nenhum campeonato cadastrado',
              description: 'Crie um campeonato para adicionar jogos.',
              action: KicksterButton(
                label: 'Criar campeonato',
                icon: Icons.add,
                onPressed: () => context.go('/competitions/new'),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KicksterDropdown<String>(
                    key: ValueKey('comp-$effectiveComp'),
                    label: 'Campeonato',
                    value: effectiveComp,
                    items: compItems
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: appDropdownItem(
                              Icons.emoji_events_outlined,
                              c.name,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      ref
                          .read(selectedCompetitionProvider.notifier)
                          .state = value;
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
                                    KicksterDropdown<String>(
                                      key: ValueKey('round-$effectiveComp'),
                                      label: 'Rodada',
                                      value:
                                          selectedRound ??
                                          roundItems.first.id,
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
                  if (!canEdit)
                    const EditRestrictionNote(
                      message:
                          'Apenas o criador do campeonato pode '
                          'gerenciar jogos.',
                    ),
                ],
              ),
              if (selectedRound != null)
                ref
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
                            return KicksterEmptyState(
                              icon: Icons.sports,
                              message: 'Nenhum jogo cadastrado',
                              description:
                                  'Crie o primeiro jogo desta rodada.',
                              action: KicksterButton(
                                label: 'Criar jogo',
                                icon: Icons.add,
                                onPressed: () => context.go(
                                  '/games/new',
                                  extra: (
                                    competitionId: effectiveComp,
                                    roundId: selectedRound,
                                    game: null,
                                  ),
                                ),
                              ),
                            );
                          }
                          final query = _query.trim().toLowerCase();
                          final filtered = query.isEmpty
                              ? items
                              : items
                                  .where(
                                    (g) =>
                                        (g.homeTeamName ?? '')
                                            .toLowerCase()
                                            .contains(query) ||
                                        (g.awayTeamName ?? '')
                                            .toLowerCase()
                                            .contains(query),
                                  )
                                  .toList(growable: false);

                          return Column(
                            children: [
                              Row(
                                children: [
                                  if (query.isNotEmpty)
                                    Text(
                                      '${filtered.length} '
                                      '${filtered.length == 1 ? 'resultado' : 'resultados'}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color:
                                            AppColors.textSecondary,
                                      ),
                                    )
                                  else
                                    Text(
                                      '${items.length} '
                                      '${items.length == 1 ? 'jogo' : 'jogos'}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color:
                                            AppColors.textSecondary,
                                      ),
                                    ),
                                  const Spacer(),
                                  SizedBox(
                                    width: 280,
                                    child: KicksterSearchField(
                                      controller: _searchController,
                                      onChanged: (value) => setState(
                                          () => _query = value),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (filtered.isEmpty)
                                const AppEmptyState(
                                  message:
                                      'Nenhum jogo encontrado',
                                  icon: Icons.search_off,
                                )
                              else
                                LayoutBuilder(
                                  builder:
                                      (context, constraints) {
                                    final columns =
                                        constraints.maxWidth >= 600
                                            ? 2
                                            : 1;
                                    return GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding:
                                          const EdgeInsets.all(16),
                                      itemCount: filtered.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount:
                                                columns,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            mainAxisExtent: 120,
                                          ),
                                      itemBuilder:
                                          (context, index) {
                                            final game =
                                                filtered[index];
                                            return _gameCard(
                                              context,
                                              game,
                                              onTap: () =>
                                                  context.push(
                                                '/games/${game.id}',
                                                extra: (
                                                  competitionId:
                                                      effectiveComp,
                                                  roundId: game.roundId,
                                                  game: game,
                                                ),
                                              ),
                                            );
                                          },
                                    );
                                  },
                                ),
                            ],
                          );
                        },
                      )
              else
                const AppEmptyState(
                    message: 'Nenhuma rodada cadastrada',
                    icon: Icons.format_list_numbered,
                  ),
            ],
          );
        },
      ),
    );
  }

  /// Card de jogo no padrão Kickster (core #439): confronto com placar em
  /// destaque e badge de status semântico.
  Widget _gameCard(
    BuildContext context,
    Game game, {
    required VoidCallback onTap,
  }) {
    return KicksterScoreCard(
      homeTeamName: game.homeTeamName ?? 'Casa',
      awayTeamName: game.awayTeamName ?? 'Fora',
      homeScore: game.homeScore ?? 0,
      awayScore: game.awayScore ?? 0,
      status: game.status,
      onTap: onTap,
    );
  }
}
