import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card de jogo exibido no calendário.
///
/// Mostra times (casa × visitante), horário formatado, campo e o status do
/// jogo. Quando [highlighted] é `true` (próximo jogo), ganha borda na cor
/// primária, fundo levemente tingido e o selo "Próximo". Quando [showRound]
/// é `true` e o jogo tem número de rodada, a rodada é exibida junto ao
/// horário.
class GameCard extends StatelessWidget {
  final Game game;
  final bool highlighted;
  final bool showRound;

  const GameCard({
    super.key,
    required this.game,
    this.highlighted = false,
    this.showRound = false,
  });

  @override
  Widget build(BuildContext context) {
    final home = game.homeTeamName?.trim();
    final away = game.awayTeamName?.trim();
    final homeLabel = (home == null || home.isEmpty) ? 'Casa a definir' : home;
    final awayLabel = (away == null || away.isEmpty)
        ? 'Visitante a definir'
        : away;
    final venue = game.venueName?.trim();
    final venueLabel = (venue == null || venue.isEmpty)
        ? 'Local não informado'
        : 'Campo: $venue';
    final dateLabel = DateFormat('dd/MM/yyyy HH:mm').format(game.scheduledAt);
    final headerLabel = showRound && game.roundNumber != null
        ? 'Rodada ${game.roundNumber} · $dateLabel'
        : dateLabel;

    return Card(
      margin: EdgeInsets.zero,
      color: highlighted ? AppColors.primary.withValues(alpha: 0.04) : null,
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.primary, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  headerLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (highlighted)
                  const _StatusLabel(
                    text: 'Próximo',
                    background: AppColors.primary,
                    foreground: Colors.white,
                  ),
                if (game.status == GameStatus.inProgress)
                  const _StatusLabel(
                    text: 'Ao vivo',
                    background: AppColors.danger,
                    foreground: Colors.white,
                  ),
                if (game.status == GameStatus.finished)
                  const _StatusLabel(
                    text: 'Encerrado',
                    background: AppColors.textSecondary,
                    foreground: Colors.white,
                  ),
                if (game.status == GameStatus.cancelled)
                  const _StatusLabel(
                    text: 'Cancelado',
                    background: AppColors.textSecondary,
                    foreground: Colors.white,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$homeLabel × $awayLabel',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (game.status == GameStatus.finished &&
                game.homeScore != null &&
                game.awayScore != null) ...[
              const SizedBox(height: 4),
              Text(
                'Placar: ${game.homeScore} × ${game.awayScore}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              venueLabel,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selo pequeno de status (Ao vivo, Encerrado, Cancelado, Próximo).
class _StatusLabel extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _StatusLabel({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
