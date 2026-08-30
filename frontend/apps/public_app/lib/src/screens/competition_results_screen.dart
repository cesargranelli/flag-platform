import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/match_score_card.dart';
import 'game_detail_screen.dart';
import 'team_detail_screen.dart';

/// Tela de resultados de um campeonato (issue #26).
///
/// Lista apenas os jogos encerrados (com placar), ordenados do mais recente
/// para o mais antigo, exibindo times, placar, campo e rodada.
class CompetitionResultsScreen extends ConsumerWidget {
  final String competitionId;
  final String competitionName;

  const CompetitionResultsScreen({
    super.key,
    required this.competitionId,
    required this.competitionName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(
      competitionGamesProvider(competitionId),
    );

    return gamesAsync.when(
      loading: () => const AppLoading(message: 'Carregando resultados...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Não foi possível carregar os resultados',
        onRetry: () =>
            ref.invalidate(competitionGamesProvider(competitionId)),
      ),
      data: (games) {
        final results = games
            .where((g) => g.status == GameStatus.finished)
            .toList()
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

        if (results.isEmpty) {
          return const AppEmptyState(
            message: 'Nenhum resultado disponível',
            icon: Icons.sports_score_outlined,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final game in results)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MatchScoreCard(
                  game: game,
                  onTap: () => context.push(
                    '/game/${game.id}',
                    extra: GameDetailArgs(
                      gameId: game.id,
                      game: game,
                      competitionName: competitionName,
                    ),
                  ),
                  onHomeTeamTap: () => openTeamDetail(
                    context,
                    teamId: game.homeTeamId,
                    teamName: game.homeTeamName,
                  ),
                  onAwayTeamTap: () => openTeamDetail(
                    context,
                    teamId: game.awayTeamId,
                    teamName: game.awayTeamName,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
