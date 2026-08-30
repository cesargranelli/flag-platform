import 'dart:async';

import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/providers.dart';
import '../widgets/match_score_card.dart';
import 'team_detail_screen.dart';

/// Argumentos de navegação do detalhe do jogo (rota `/game/:id`).
///
/// Carrega o jogo completo (times, campo, mapa) e o nome do campeonato para
/// exibição imediata; em deep links (sem `extra`) a tela busca o jogo por id.
class GameDetailArgs {
  final String gameId;
  final Game? game;
  final String competitionName;

  const GameDetailArgs({
    required this.gameId,
    this.game,
    this.competitionName = '',
  });
}

/// Tela de detalhe de um jogo (issue #28).
///
/// Durante partidas ao vivo o placar é atualizado automaticamente a cada 10s
/// (issue #30). Os nomes de times/campo vêm da listagem quando disponíveis.
class GameDetailScreen extends ConsumerStatefulWidget {
  final String gameId;
  final Game? game;
  final String competitionName;

  const GameDetailScreen({
    super.key,
    required this.gameId,
    this.game,
    this.competitionName = '',
  });

  @override
  ConsumerState<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends ConsumerState<GameDetailScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoRefreshIfNeeded();
  }

  /// Inicia o timer de auto-refresh apenas se o jogo estiver em andamento.
  void _startAutoRefreshIfNeeded() {
    final game = ref.read(gameDetailProvider(widget.gameId)).valueOrNull;
    if (game != null && game.status != GameStatus.inProgress) {
      _timer?.cancel();
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.invalidate(gameDetailProvider(widget.gameId));
        ref.invalidate(gameScoreEventsProvider(widget.gameId));
      }
    });
  }

  @override
  void didUpdateWidget(covariant GameDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startAutoRefreshIfNeeded();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(gameDetailProvider(widget.gameId));
    final eventsAsync = ref.watch(gameScoreEventsProvider(widget.gameId));

    return Scaffold(
      appBar: AppBar(title: const Text('Jogo')),
      body: gameAsync.when(
        loading: () => const AppLoading(message: 'Carregando jogo...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar o jogo',
          onRetry: () => ref.invalidate(gameDetailProvider(widget.gameId)),
        ),
        data: (game) {
          // Reavalia o timer de auto-refresh quando o jogo carrega.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startAutoRefreshIfNeeded();
          });
          return _GameDetailContent(
            game: game,
            namesFrom: widget.game,
            competitionName: widget.competitionName,
            events: eventsAsync.valueOrNull ?? const [],
          );
        },
      ),
    );
  }
}

/// Junta o jogo buscado por id com os dados vindos da listagem (`extra`),
/// priorizando nomes/ids/campo do `extra` quando disponíveis.
Game _mergeDisplay(Game base, Game? names) {
  if (names == null) return base;
  return Game(
    id: base.id,
    roundId: base.roundId,
    competitionId: names.competitionId ?? base.competitionId,
    homeTeamId: names.homeTeamId ?? base.homeTeamId,
    awayTeamId: names.awayTeamId ?? base.awayTeamId,
    roundNumber: base.roundNumber ?? names.roundNumber,
    homeTeamName: names.homeTeamName ?? base.homeTeamName,
    awayTeamName: names.awayTeamName ?? base.awayTeamName,
    venueId: names.venueId ?? base.venueId,
    venueName: names.venueName ?? base.venueName,
    venueAddress: names.venueAddress ?? base.venueAddress,
    venueMapsUrl: names.venueMapsUrl ?? base.venueMapsUrl,
    scheduledAt: base.scheduledAt,
    status: base.status,
    homeScore: base.homeScore,
    awayScore: base.awayScore,
  );
}

/// Conteúdo do detalhe do jogo: header de confronto, horário e campo.
class _GameDetailContent extends StatelessWidget {
  final Game game;
  final Game? namesFrom;
  final String competitionName;
  final List<ScoreEvent> events;

  const _GameDetailContent({
    required this.game,
    required this.namesFrom,
    required this.competitionName,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final display = _mergeDisplay(game, namesFrom);
    final venueName = display.venueName?.trim();
    final venueAddress = display.venueAddress?.trim();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (competitionName.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  competitionName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        MatchScoreCard(
          game: display,
          onHomeTeamTap: () => openTeamDetail(
            context,
            teamId: display.homeTeamId,
            teamName: display.homeTeamName,
          ),
          onAwayTeamTap: () => openTeamDetail(
            context,
            teamId: display.awayTeamId,
            teamName: display.awayTeamName,
          ),
        ),
        const SizedBox(height: 12),
        if (events.isNotEmpty) ...[
          _InfoCard(
            icon: Icons.timeline,
            title: 'Sequência de pontos',
            child: ScoreTimeline(game: game, events: events),
          ),
          const SizedBox(height: 12),
        ],
        _InfoCard(
          icon: Icons.stadium_outlined,
          title: 'Local',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (venueName == null || venueName.isEmpty)
                    ? 'Local não informado'
                    : venueName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (venueAddress != null && venueAddress.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  venueAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (display.venueMapsUrl != null &&
                  display.venueMapsUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _openMap(context, display.venueMapsUrl!),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Abrir no mapa'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Abre o link do campo no Google Maps (aplicativo ou navegador).
  Future<void> _openMap(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o mapa')),
      );
    }
  }
}

/// Cartão de informação com ícone e título.
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
