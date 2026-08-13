import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/providers.dart';

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
/// Recebe o [gameId] via rota; quando o jogo já foi carregado na listagem,
/// o objeto completo pode ser passado via `extra` para exibição imediata.
/// Caso contrário, busca o jogo por id na API.
class GameDetailScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = game != null
        ? AsyncValue.data(game!)
        : ref.watch(gameDetailProvider(gameId));

    return Scaffold(
      appBar: AppBar(title: const Text('Jogo')),
      body: gameAsync.when(
        loading: () => const AppLoading(message: 'Carregando jogo...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar o jogo',
          onRetry: () => ref.invalidate(gameDetailProvider(gameId)),
        ),
        data: (game) => _GameDetailContent(
          game: game,
          competitionName: competitionName,
        ),
      ),
    );
  }
}

/// Conteúdo do detalhe do jogo: times, horário, status, placar e campo.
class _GameDetailContent extends StatelessWidget {
  final Game game;
  final String competitionName;

  const _GameDetailContent({required this.game, required this.competitionName});

  @override
  Widget build(BuildContext context) {
    final home = game.homeTeamName?.trim();
    final away = game.awayTeamName?.trim();
    final homeLabel = (home == null || home.isEmpty) ? 'Casa a definir' : home;
    final awayLabel = (away == null || away.isEmpty)
        ? 'Visitante a definir'
        : away;
    final dateLabel = DateFormat('dd/MM/yyyy \'às\' HH:mm').format(
      game.scheduledAt,
    );
    final venueName = game.venueName?.trim();
    final venueAddress = game.venueAddress?.trim();

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
        Text(
          '$homeLabel × $awayLabel',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (game.roundNumber != null) ...[
          const SizedBox(height: 4),
          Text(
            'Rodada ${game.roundNumber}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              dateLabel,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (game.status == GameStatus.finished &&
            game.homeScore != null &&
            game.awayScore != null) ...[
          _InfoCard(
            icon: Icons.sports_score,
            title: 'Placar final',
            child: Text(
              '${game.homeScore} × ${game.awayScore}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _InfoCard(
          icon: Icons.sports_soccer,
          title: 'Status',
          child: Text(
            _statusLabel(game.status),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _statusColor(game.status),
            ),
          ),
        ),
        const SizedBox(height: 12),
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
              if (game.venueMapsUrl != null && game.venueMapsUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _openMap(context, game.venueMapsUrl!),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o mapa')));
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

String _statusLabel(GameStatus status) => switch (status) {
  GameStatus.scheduled => 'Agendado',
  GameStatus.inProgress => 'Ao vivo',
  GameStatus.finished => 'Encerrado',
  GameStatus.cancelled => 'Cancelado',
};

Color _statusColor(GameStatus status) => switch (status) {
  GameStatus.scheduled => AppColors.textSecondary,
  GameStatus.inProgress => AppColors.danger,
  GameStatus.finished => AppColors.success,
  GameStatus.cancelled => AppColors.textSecondary,
};
