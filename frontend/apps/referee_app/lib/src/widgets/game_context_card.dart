import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';

import '../utils/datetime_utils.dart';
import 'status_badges.dart';

/// Card de contexto do jogo selecionado: confronto, horário, status e local
/// (issue #425#17).
///
/// Compartilhado entre a operação e o check-in — substitui os cards
/// duplicados que omitiam o local (campo) do jogo.
class GameContextCard extends StatelessWidget {
  const GameContextCard({super.key, required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final venueParts = <String>[
      if (game.venueName != null && game.venueName!.isNotEmpty) game.venueName!,
      if (game.venueAddress != null && game.venueAddress!.isNotEmpty)
        game.venueAddress!,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${game.homeTeamName ?? 'Casa'} x '
                    '${game.awayTeamName ?? 'Fora'}',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                GameStatusChip(status: game.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatDateTime(game.scheduledAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (venueParts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.stadium_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      venueParts.join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}