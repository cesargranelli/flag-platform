import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Tela "Lance a Lance" (Play by Play): timeline de lances de futebol americano.
///
/// Mostra os lances do jogo com:
/// - Cabeçalho com os 2 times separados
/// - Lances do lado do time em ação
/// - Cards com foto do jogador, nome, ação e tempo
/// - Linha separando os lados
class PlayByPlayScreen extends ConsumerWidget {
  final String gameId;
  final Game? game;

  const PlayByPlayScreen({
    super.key,
    required this.gameId,
    this.game,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playsAsync = ref.watch(playByPlayProvider(gameId));
    final gameData = game;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lance a Lance'),
        actions: [
          if (gameData?.status == GameStatus.inProgress)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Semantics(
                label: 'Jogo ao vivo',
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LiveIndicator(),
                    SizedBox(width: 4),
                    Text(
                      'AO VIVO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header do jogo (placar)
          if (gameData != null)
            _GameHeader(
              game: gameData,
              currentQuarter: playsAsync.valueOrNull?.isNotEmpty == true
                  ? playsAsync.valueOrNull!.last.quarter
                  : null,
            ),

          // Lista de lances
          Expanded(
            child: playsAsync.when(
              loading: () => const AppLoading(message: 'Carregando lances...'),
              error: (error, stack) => AppErrorState(
                message: 'Não foi possível carregar os lances',
                onRetry: () => ref.invalidate(playByPlayProvider(gameId)),
              ),
              data: (plays) {
                if (plays.isEmpty) {
                  return const AppEmptyState(
                    message: 'Nenhum lance registrado',
                    icon: Icons.sports_football_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: plays.length,
                  itemBuilder: (context, index) {
                    final play = plays[index];
                    final isFirstInQuarter = index == 0 || plays[index - 1].quarter != play.quarter;

                    return Column(
                      children: [
                        if (isFirstInQuarter) ...[
                          _QuarterSeparator(quarter: play.quarter),
                          const SizedBox(height: 12),
                        ],
                        _PlayCard(play: play),
                        if (index < plays.length - 1) ...[
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 48),
                            child: Divider(height: 1, color: AppColors.grayFill),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Header do jogo com placar e times.
class _GameHeader extends StatelessWidget {
  final Game game;
  final String? currentQuarter;

  const _GameHeader({required this.game, this.currentQuarter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Time da casa
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  game.homeTeamName ?? 'Casa',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Placar
          Column(
            children: [
              Text(
                '${game.homeScore ?? 0} × ${game.awayScore ?? 0}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.grayFill,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${currentQuarter ?? 'Q1'} · ${game.roundNumber ?? 1}ª rodada',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          // Time visitante
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  game.awayTeamName ?? 'Visitante',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Separador de quarter.
class _QuarterSeparator extends StatelessWidget {
  final String quarter;

  const _QuarterSeparator({required this.quarter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.grayFill)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              quarter,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.grayFill)),
        ],
      ),
    );
  }
}

/// Card de lance individual.
///
/// O layout inverte conforme o lado da ação:
/// - Time A (laranja): [ícone] [conteúdo] [horário] (borda à esquerda)
/// - Time B (azul): [horário] [conteúdo] [ícone] (borda à direita)
class _PlayCard extends StatelessWidget {
  final Play play;

  const _PlayCard({required this.play});

  @override
  Widget build(BuildContext context) {
    final isTeamA = play.teamId == 'team-a';
    final teamColor = isTeamA ? AppColors.primary : AppColors.secondary;

    final iconWidget = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: teamColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _playIcon(play.type),
        color: teamColor,
        size: 20,
      ),
    );

    final contentWidget = Expanded(
      child: Column(
        crossAxisAlignment:
            isTeamA ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            play.description,
            textAlign: isTeamA ? TextAlign.left : TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          if (play.isFirstDown || play.isTouchdown || play.isTurnover) ...[
            const SizedBox(height: 4),
            _PlayBadge(play: play),
          ],
        ],
      ),
    );

    final timeWidget = Text(
      play.time,
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
      ),
    );

    return Semantics(
      label: '${play.teamName}: ${play.description}',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: isTeamA ? BorderSide(color: teamColor, width: 3) : BorderSide.none,
            right: isTeamA ? BorderSide.none : BorderSide(color: teamColor, width: 3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (isTeamA) ...[
                iconWidget,
                const SizedBox(width: 12),
                contentWidget,
                timeWidget,
              ] else ...[
                timeWidget,
                const SizedBox(width: 12),
                contentWidget,
                const SizedBox(width: 12),
                iconWidget,
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _playIcon(PlayType type) {
    return switch (type) {
      PlayType.run => Icons.directions_run,
      PlayType.pass => Icons.sports_football,
      PlayType.touchdown => Icons.emoji_events,
      PlayType.interception => Icons.block,
      PlayType.fieldGoal => Icons.flag,
      PlayType.punt => Icons.arrow_upward,
      PlayType.kickoff => Icons.play_arrow,
      PlayType.penalty => Icons.flag,
      PlayType.firstDown => Icons.check_circle,
    };
  }
}

/// Badge de impacto do lance.
class _PlayBadge extends StatelessWidget {
  final Play play;

  const _PlayBadge({required this.play});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    if (play.isTouchdown) {
      color = AppColors.success;
      label = 'Touchdown!';
    } else if (play.isTurnover) {
      color = AppColors.danger;
      label = 'Turnover';
    } else if (play.isFirstDown) {
      color = AppColors.success;
      label = '1º Down';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Indicador "AO VIVO" com animação de pulso.
class _LiveIndicator extends StatefulWidget {
  const _LiveIndicator();

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.5,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
