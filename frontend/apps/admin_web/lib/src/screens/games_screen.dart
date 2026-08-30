import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../widgets/app_entity_list_screen.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);
    final selectedRound = ref.watch(selectedRoundProvider);

    final compItems = competitions.valueOrNull ?? const [];
    // P4 #461: campeonato efetivo = selecionado ?? primeiro da lista.
    final effectiveComp = ref.watch(effectiveCompetitionProvider);

    // Rodadas do campeonato efetivo + rodada "efetiva" (B1 #457): quando
    // nenhuma rodada foi selecionada, usa a primeira — a lista de jogos
    // aparece sem depender de um clique no dropdown.
    final roundsAsync = effectiveComp != null
        ? ref.watch(roundsProvider(effectiveComp))
        : null;
    final roundItems = roundsAsync?.valueOrNull ?? const <Round>[];
    final effectiveRound = selectedRound ?? roundItems.firstOrNull?.id;

    // Issue #261: criação/edição de jogos (incluída a importação CSV)
    // exige ser criador do campeonato ou ADMIN.
    final selectedCompetitionObj = compItems
        .where((c) => c.id == effectiveComp)
        .firstOrNull;
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider.select((a) => a.state.user)),
      selectedCompetitionObj,
    );

    return AppScreen(
      title: 'Jogos',
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem('Jogos'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Actions
          Row(
            children: [
              const Spacer(),
              if (effectiveRound != null && canEdit)
                KicksterButton(
                  label: 'Importar',
                  icon: Icons.upload_file,
                  variant: KicksterButtonVariant.outline,
                  onPressed: () => context.push(
                    '/games/import',
                    extra: (
                      roundId: effectiveRound,
                      competitionId: effectiveComp,
                    ),
                  ),
                ),
              if (effectiveRound != null && canEdit)
                const SizedBox(width: 8),
              if (effectiveComp != null && canEdit)
                KicksterButton(
                  label: 'Novo',
                  icon: Icons.add,
                  onPressed: () => context.go(
                    '/games/new',
                    extra: (
                      competitionId: effectiveComp,
                      roundId: effectiveRound,
                      game: null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Conteúdo (Expanded para dar altura finita ao grid)
          Expanded(
            child: competitions.when(
              loading: () =>
                  const AppLoading(message: 'Carregando campeonatos...'),
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
                            ref.read(selectedRoundProvider.notifier).state =
                                null;
                          },
                        ),
                        const SizedBox(height: 12),
                        (effectiveComp != null)
                            ? roundsAsync!.when(
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
                                      value: effectiveRound,
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
                                      onChanged: (value) => ref
                                          .read(
                                            selectedRoundProvider.notifier,
                                          )
                                          .state = value,
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
                    // Grid em altura finita (Expanded) → virtualização real.
                    const SizedBox(height: 16),
                    Expanded(
                      child: effectiveRound != null
                          ? ref
                                .watch(gamesByRoundProvider(effectiveRound))
                                .when(
                                  loading: () => const AppLoading(
                                    message: 'Carregando jogos...',
                                  ),
                                  error: (error, stackTrace) =>
                                      AppErrorState(
                                    message:
                                        'Não foi possível carregar os jogos',
                                    onRetry: () => ref.invalidate(
                                      gamesByRoundProvider(effectiveRound),
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
                                              roundId: effectiveRound,
                                              game: null,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return AppEntityListScreen<Game>(
                                      items: items,
                                      cardBuilder: (game) => _gameCard(
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
                                      ),
                                      searchField: _searchController,
                                      countLabel: 'jogos',
                                      countLabelSingular: 'jogo',
                                      emptyMessage: 'Nenhum jogo encontrado',
                                      mainAxisExtent: 120,
                                      gridPadding:
                                          const EdgeInsets.all(16),
                                      filter: (all, query) => query.isEmpty
                                          ? all
                                          : all
                                              .where(
                                                (g) =>
                                                    (g.homeTeamName ?? '')
                                                        .toLowerCase()
                                                        .contains(query) ||
                                                    (g.awayTeamName ?? '')
                                                        .toLowerCase()
                                                        .contains(query),
                                              )
                                              .toList(growable: false),
                                    );
                                  },
                                )
                          : const AppEmptyState(
                              message: 'Nenhuma rodada cadastrada',
                              icon: Icons.format_list_numbered,
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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
