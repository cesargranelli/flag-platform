import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'match_status_badge.dart';

/// Card de partida no padrão live score.
///
/// Layout: [nome time casa | placar casa] [status central] [placar fora |
/// nome time fora]. Placares grandes e destacados quando o jogo está em
/// andamento ou encerrado; quando agendado, o horário ocupa o centro e os
/// espaços de placar ficam reservados para manter o alinhamento da lista.
///
/// Os nomes dos times viram alvos de toque quando [onHomeTeamTap]/
/// [onAwayTeamTap] são informados (navegação para a página do time).
/// [onTap] abre o detalhe do jogo. Quando [highlighted] é `true`
/// (próximo jogo), ganha borda/fundo na cor primária e o selo "Próximo".
class MatchScoreCard extends StatelessWidget {
  final Game game;
  final bool highlighted;
  final bool showMeta;
  final bool showRound;
  final bool showVenue;
  final VoidCallback? onHomeTeamTap;
  final VoidCallback? onAwayTeamTap;
  final VoidCallback? onTap;

  const MatchScoreCard({
    super.key,
    required this.game,
    this.highlighted = false,
    this.showMeta = false,
    this.showRound = false,
    this.showVenue = false,
    this.onHomeTeamTap,
    this.onAwayTeamTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final homeLabel = _teamLabel(game.homeTeamName, fallback: 'Casa a definir');
    final awayLabel = _teamLabel(
      game.awayTeamName,
      fallback: 'Visitante a definir',
    );

    // Placares só aparecem quando o jogo está rolando/encerrado e há
    // pontuação dos dois lados; caso contrário os espaços ficam reservados.
    final showScores =
        (game.status == GameStatus.inProgress ||
            game.status == GameStatus.finished) &&
        game.homeScore != null &&
        game.awayScore != null;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: highlighted ? AppColors.primary.withValues(alpha: 0.04) : null,
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.primary, width: 2),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showMeta) ...[
                _MetaLine(
                  game: game,
                  showRound: showRound,
                  highlighted: highlighted,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _TeamName(
                      label: homeLabel,
                      textAlign: TextAlign.right,
                      onTap: onHomeTeamTap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ScoreText(
                    score: showScores ? game.homeScore : null,
                    color: game.status == GameStatus.finished
                        ? AppColors.success
                        : AppColors.textPrimary,
                  ),
                  const SizedBox(width: 10),
                  _CenterInfo(
                    status: game.status,
                    scheduledAt: game.scheduledAt,
                    showScores: showScores,
                  ),
                  const SizedBox(width: 10),
                  _ScoreText(
                    score: showScores ? game.awayScore : null,
                    color: game.status == GameStatus.finished
                        ? AppColors.success
                        : AppColors.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TeamName(
                      label: awayLabel,
                      textAlign: TextAlign.left,
                      onTap: onAwayTeamTap,
                    ),
                  ),
                ],
              ),
              if (showVenue) ...[
                const SizedBox(height: 12),
                _VenueLine(game: game),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _teamLabel(String? name, {required String fallback}) {
    final trimmed = name?.trim();
    return (trimmed == null || trimmed.isEmpty) ? fallback : trimmed;
  }
}

/// Linha superior do card: data/hora (+ rodada) e selo "Próximo".
class _MetaLine extends StatelessWidget {
  final Game game;
  final bool showRound;
  final bool highlighted;

  const _MetaLine({
    required this.game,
    required this.showRound,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd/MM/yyyy HH:mm').format(game.scheduledAt);
    final metaLabel = showRound && game.roundNumber != null
        ? 'Rodada ${game.roundNumber} · $dateLabel'
        : dateLabel;

    return Row(
      children: [
        const Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            metaLabel,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (highlighted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'Próximo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

/// Nome do time; quando tocável, garante alvo de toque de no mínimo 48px.
class _TeamName extends StatelessWidget {
  final String label;
  final TextAlign textAlign;
  final VoidCallback? onTap;

  const _TeamName({required this.label, required this.textAlign, this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.textPrimary,
      ),
    );

    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: text,
      );
    }

    return Semantics(
      button: true,
      label: 'Ver página do time $label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: textAlign == TextAlign.right
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: text,
        ),
      ),
    );
  }
}

/// Placar grande do lado do time; largura fixa para alinhar as linhas
/// da lista mesmo em jogos sem pontuação exibida.
class _ScoreText extends StatelessWidget {
  final int? score;
  final Color color;

  /// Largura suficiente para placares de dois dígitos com folga.
  static const double _width = 36;

  const _ScoreText({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      child: Text(
        score?.toString() ?? '',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 30,
          height: 1.0,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

/// Conteúdo central entre os placares: horário (agendado) ou badge de status.
class _CenterInfo extends StatelessWidget {
  final GameStatus status;
  final DateTime scheduledAt;
  final bool showScores;

  const _CenterInfo({
    required this.status,
    required this.scheduledAt,
    required this.showScores,
  });

  @override
  Widget build(BuildContext context) {
    if (status == GameStatus.scheduled) {
      return Text(
        DateFormat('HH:mm').format(scheduledAt),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      );
    }
    // Nos demais estados o badge centraliza a informação; nos jogos com
    // placar ele fica entre os números, como separador do confronto.
    return Padding(
      padding: EdgeInsets.symmetric(vertical: showScores ? 0 : 6),
      child: MatchStatusBadge(status: status, scheduledAt: scheduledAt),
    );
  }
}

/// Rodapé com o campo da partida.
class _VenueLine extends StatelessWidget {
  final Game game;

  const _VenueLine({required this.game});

  @override
  Widget build(BuildContext context) {
    final venue = game.venueName?.trim();
    final venueLabel = (venue == null || venue.isEmpty)
        ? 'Local não informado'
        : venue;

    return Row(
      children: [
        const Icon(
          Icons.stadium_outlined,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            venueLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
