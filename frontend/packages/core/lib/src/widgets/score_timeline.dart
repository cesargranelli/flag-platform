import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Timeline de eventos de pontuação de uma partida.
///
/// Linha vertical com marcadores por minuto; eventos do time da casa à
/// esquerda e do visitante à direita. O "minuto" é derivado da diferença
/// entre o momento do evento e o início agendado da partida.
class ScoreTimeline extends StatelessWidget {
  const ScoreTimeline({
    super.key,
    required this.game,
    required this.events,
  });

  final Game game;
  final List<ScoreEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = [...events]..sort((a, b) {
      final ta = a.createdAt;
      final tb = b.createdAt;
      if (ta == null && tb == null) return a.id.compareTo(b.id);
      if (ta == null) return 1;
      if (tb == null) return -1;
      return ta.compareTo(tb);
    });
    final homeId = game.homeTeamId;
    final awayId = game.awayTeamId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final event in sorted) _timelineRow(event, homeId, awayId),
      ],
    );
  }

  Widget _timelineRow(ScoreEvent event, String? homeId, String? awayId) {
    final isHome = event.teamId == homeId;
    final isAway = event.teamId == awayId;
    final minute = _minuteOf(event);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Lado da casa (eventos da casa à esquerda).
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: isHome ? _eventBadge(true, minute) : const SizedBox.shrink(),
            ),
          ),
          // Eixo vertical + marcador.
          Column(
            children: [
              Container(
                width: 2,
                height: 28,
                color: AppColors.textSecondary.withValues(alpha: 0.3),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isHome
                      ? AppColors.primary
                      : (isAway ? AppColors.success : AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Lado do visitante.
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: isAway ? _eventBadge(false, minute) : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventBadge(bool isHome, int minute) {
    final team = isHome ? 'time da casa' : 'time visitante';
    return Semantics(
      label: 'Ponto para o $team no minuto $minute',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: (isHome ? AppColors.primary : AppColors.success)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Ponto · $minute\'',
          style: TextStyle(
            fontSize: 12,
            color: isHome ? AppColors.primary : AppColors.success,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  int _minuteOf(ScoreEvent event) {
    final createdAt = event.createdAt;
    final scheduledAt = game.scheduledAt;
    if (createdAt == null) return 0;
    final diff = createdAt.difference(scheduledAt);
    final minutes = diff.inMinutes.clamp(0, 99);
    return minutes;
  }
}
