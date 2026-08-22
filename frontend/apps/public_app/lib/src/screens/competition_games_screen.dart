import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/match_score_card.dart';
import 'game_detail_screen.dart';
import 'team_detail_screen.dart';

/// Tela de calendário de jogos de um campeonato (issue #25).
///
/// Lista os jogos ordenados por data, permite filtrar por rodada via chips e
/// destaca no topo os próximos jogos agendados.
class CompetitionGamesScreen extends ConsumerStatefulWidget {
  final String competitionId;
  final String competitionName;

  const CompetitionGamesScreen({
    super.key,
    required this.competitionId,
    required this.competitionName,
  });

  @override
  ConsumerState<CompetitionGamesScreen> createState() =>
      _CompetitionGamesScreenState();
}

class _CompetitionGamesScreenState
    extends ConsumerState<CompetitionGamesScreen> {
  /// Rodada selecionada no filtro; `null` significa "Todas".
  int? _selectedRound;

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(
      competitionGamesProvider(widget.competitionId),
    );
    final title = widget.competitionName.isEmpty
        ? 'Calendário de jogos'
        : widget.competitionName;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: gamesAsync.when(
        loading: () => const AppLoading(message: 'Carregando jogos...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar os jogos',
          onRetry: () =>
              ref.invalidate(competitionGamesProvider(widget.competitionId)),
        ),
        data: (games) {
          if (games.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhum jogo disponível',
              icon: Icons.sports_football,
            );
          }
          return _GamesView(
            games: games,
            selectedRound: _selectedRound,
            competitionName: widget.competitionName,
            onRoundSelected: (round) => setState(() => _selectedRound = round),
          );
        },
      ),
    );
  }
}

/// Conteúdo do calendário: filtro de rodada, destaques e lista completa.
class _GamesView extends StatelessWidget {
  final List<Game> games;
  final int? selectedRound;
  final String competitionName;
  final ValueChanged<int?> onRoundSelected;

  const _GamesView({
    required this.games,
    required this.selectedRound,
    required this.competitionName,
    required this.onRoundSelected,
  });

  @override
  Widget build(BuildContext context) {
    final rounds =
        games.map((game) => game.roundNumber).whereType<int>().toSet().toList()
          ..sort();

    final visibleGames = selectedRound == null
        ? games
        : games.where((game) => game.roundNumber == selectedRound).toList();

    // Destaques só aparecem na visão "Todas": agendados no futuro, até 3.
    final upcoming = selectedRound == null
        ? _upcomingGames(games)
        : const <Game>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RoundFilter(
          rounds: rounds,
          selectedRound: selectedRound,
          onSelected: onRoundSelected,
        ),
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionTitle('Próximos jogos'),
          const SizedBox(height: 8),
          ...upcoming.map(
            (game) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MatchScoreCard(
                game: game,
                highlighted: true,
                showMeta: true,
                showVenue: true,
                onTap: () => _openGameDetail(context, game),
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
          ),
          const SizedBox(height: 8),
          const _SectionTitle('Todos os jogos'),
          const SizedBox(height: 8),
        ],
        if (visibleGames.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'Nenhum jogo nesta rodada',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          )
        else
          ...visibleGames.map(
            (game) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MatchScoreCard(
                game: game,
                showMeta: true,
                showVenue: true,
                onTap: () => _openGameDetail(context, game),
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
          ),
      ],
    );
  }

  /// Navega para o detalhe do jogo passando o objeto completo via `extra`.
  void _openGameDetail(BuildContext context, Game game) {
    context.push(
      '/game/${game.id}',
      extra: GameDetailArgs(
        gameId: game.id,
        game: game,
        competitionName: competitionName,
      ),
    );
  }

  /// Próximos jogos agendados (status SCHEDULED e data futura), até 3,
  /// ordenados do mais próximo para o mais distante.
  List<Game> _upcomingGames(List<Game> games) {
    final now = DateTime.now();
    final upcoming =
        games
            .where(
              (game) =>
                  game.status == GameStatus.scheduled &&
                  game.scheduledAt.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return upcoming.take(3).toList();
  }
}

/// Título de seção do calendário.
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// Filtro horizontal por rodada ("Todas" + uma chip por rodada distinta).
class _RoundFilter extends StatelessWidget {
  final List<int> rounds;
  final int? selectedRound;
  final ValueChanged<int?> onSelected;

  const _RoundFilter({
    required this.rounds,
    required this.selectedRound,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Todas'),
              selected: selectedRound == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final round in rounds)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('Rodada $round'),
                selected: selectedRound == round,
                onSelected: (_) => onSelected(round),
              ),
            ),
        ],
      ),
    );
  }
}
