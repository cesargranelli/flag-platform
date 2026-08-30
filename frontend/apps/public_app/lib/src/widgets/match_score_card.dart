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
  final bool showClubLogos;
  final bool showPlayByPlay;
  final VoidCallback? onHomeTeamTap;
  final VoidCallback? onAwayTeamTap;
  final VoidCallback? onTap;
  final VoidCallback? onPlayByPlayTap;

  const MatchScoreCard({
    super.key,
    required this.game,
    this.highlighted = false,
    this.showMeta = true,
    this.showRound = true,
    this.showVenue = true,
    this.showClubLogos = true,
    this.showPlayByPlay = false,
    this.onHomeTeamTap,
    this.onAwayTeamTap,
    this.onTap,
    this.onPlayByPlayTap,
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
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
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
                        child: Column(
                          children: [
                            if (showClubLogos) ...[
                              _ClubLogo(teamName: homeLabel, color: AppColors.primary),
                              const SizedBox(height: 4),
                            ],
                            _TeamName(
                              label: homeLabel,
                              textAlign: TextAlign.right,
                              onTap: onHomeTeamTap,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ScoreText(
                        score: showScores ? game.homeScore : null,
                        color: game.status == GameStatus.finished
                            ? AppColors.success
                            : game.status == GameStatus.inProgress
                                ? AppColors.primary
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
                            : game.status == GameStatus.inProgress
                                ? AppColors.primary
                                : AppColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            if (showClubLogos) ...[
                              _ClubLogo(teamName: awayLabel, color: AppColors.secondary),
                              const SizedBox(height: 4),
                            ],
                            _TeamName(
                              label: awayLabel,
                              textAlign: TextAlign.left,
                              onTap: onAwayTeamTap,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (showVenue) ...[
                    const SizedBox(height: 12),
                    _VenueLine(game: game),
                  ],
                  if (showPlayByPlay && onPlayByPlayTap != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onPlayByPlayTap,
                        icon: const Icon(Icons.sports_football, size: 18),
                        label: const Text('Lance a Lance'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _teamLabel(String? name, {required String fallback}) {
    final trimmed = name?.trim();
    return (trimmed == null || trimmed.isEmpty) ? fallback : trimmed;
  }
}

/// Linha superior do card: ícone de status, data/hora (+ rodada),
/// label "AO VIVO" para jogos em andamento e selo "Próximo".
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
        _StatusIcon(status: game.status),
        const SizedBox(width: 6),
        if (game.status == GameStatus.inProgress) ...[
          const Text(
            'AO VIVO',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '·',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
        ],
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
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: AppColors.textSecondary,
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

/// Ícone placeholder do escudo do time — exibe as iniciais do nome.
///
/// Em produção será substituído por Image.asset/Image.network com o escudo real.
class _ClubLogo extends StatelessWidget {
  final String teamName;
  final Color color;

  const _ClubLogo({required this.teamName, required this.color});

  @override
  Widget build(BuildContext context) {
    final initials = _extractInitials(teamName);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  /// Extrai até 2 iniciais do nome do time.
  static String _extractInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
  }
}

/// Indicador pulsante para jogos ao vivo (decorativo, sutil).
///
/// Animação de opacidade que repete indefinidamente, sinalizando que o
/// jogo está em andamento. Usado na linha meta do card e como componente
/// reutilizável.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
      opacity: Tween<double>(
        begin: 0.35,
        end: 1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: ExcludeSemantics(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.danger,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Ícone de status na linha meta: ponto pulsante (ao vivo), calendário
/// (agendado), checkmark (encerrado) ou x (cancelado).
class _StatusIcon extends StatelessWidget {
  final GameStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      GameStatus.inProgress => const _PulsingDot(),
      GameStatus.scheduled => const Icon(
        Icons.calendar_today,
        size: 16,
        color: AppColors.textSecondary,
      ),
      GameStatus.open => const Icon(
        Icons.login,
        size: 16,
        color: AppColors.textSecondary,
      ),
      GameStatus.conference => const Icon(
        Icons.assignment_turned_in,
        size: 16,
        color: AppColors.textSecondary,
      ),
      GameStatus.finished => const Icon(
        Icons.check_circle,
        size: 16,
        color: AppColors.success,
      ),
      GameStatus.cancelled => const Icon(
        Icons.cancel,
        size: 16,
        color: AppColors.textSecondary,
      ),
    };
  }
}
