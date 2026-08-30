import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import 'team_detail_screen.dart';

/// Tela de classificação de um campeonato (issue #27).
///
/// Exibe a tabela (posição, time, PJ, V, D, SG, PTS) do campeonato no
/// padrão live score: posição em chip destacado, pontos em evidência e
/// linhas tocáveis que abrem a página do time (issue #124). Atualização
/// via pull to refresh. No fluxo único (migração V24) a classificação é
/// por campeonato — não há mais categorias.
class CompetitionStandingsScreen extends ConsumerWidget {
  final String competitionId;
  final String competitionName;

  const CompetitionStandingsScreen({
    super.key,
    required this.competitionId,
    required this.competitionName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(
      competitionStandingsProvider(competitionId),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(competitionStandingsProvider(competitionId));
        await ref.read(competitionStandingsProvider(competitionId).future);
      },
      child: standingsAsync.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            AppLoading(message: 'Carregando classificação...'),
          ],
        ),
        error: (error, stackTrace) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            AppErrorState(
              message: 'Não foi possível carregar a classificação',
              onRetry: () =>
                  ref.invalidate(competitionStandingsProvider(competitionId)),
            ),
          ],
        ),
        data: (standings) {
          if (standings.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                AppEmptyState(
                  message: 'Nenhuma classificação disponível',
                  icon: Icons.leaderboard_outlined,
                ),
              ],
            );
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [_StandingsTable(standings: standings)],
          );
        },
      ),
    );
  }
}

/// Tabela de classificação com cabeçalho e linhas de cada posição.
class _StandingsTable extends StatelessWidget {
  final List<Standing> standings;

  const _StandingsTable({required this.standings});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const _TableHeader(),
          for (final standing in standings) _StandingRow(standing: standing),
        ],
      ),
    );
  }
}

/// Cabeçalho fixo da tabela: Pos, Time, PJ, V, D, SG, PTS.
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              'Pos',
              style: _headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 10),
          Expanded(child: Text('Time', style: _headerStyle)),
          SizedBox(width: 36, child: _HeaderCell('PJ')),
          SizedBox(width: 36, child: _HeaderCell('V')),
          SizedBox(width: 36, child: _HeaderCell('D')),
          SizedBox(width: 44, child: _HeaderCell('SG')),
          SizedBox(width: 8),
          SizedBox(width: 48, child: _HeaderCell('PTS')),
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: AppColors.textPrimary,
);

class _HeaderCell extends StatelessWidget {
  final String label;

  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label, style: _headerStyle, textAlign: TextAlign.center);
  }
}

/// Linha de uma posição na tabela; o líder ganha destaque visual e cada
/// linha abre a página do time ao ser tocada.
class _StandingRow extends StatelessWidget {
  final Standing standing;

  const _StandingRow({required this.standing});

  @override
  Widget build(BuildContext context) {
    final isLeader = standing.position == 1;
    final teamLabel = (standing.teamName?.trim().isEmpty ?? true)
        ? 'Time não informado'
        : standing.teamName!.trim();
    final goalDifference = standing.goalDifference > 0
        ? '+${standing.goalDifference}'
        : '${standing.goalDifference}';

    return Semantics(
      label:
          'Posição ${standing.position}, $teamLabel, ${standing.points} pontos',
      button: true,
      child: InkWell(
        onTap: () => openTeamDetail(
          context,
          teamId: standing.teamId,
          teamName: standing.teamName,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isLeader ? AppColors.primary.withValues(alpha: 0.04) : null,
            border: Border(
              top: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: 0.15),
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              _PositionChip(position: standing.position),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      teamLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isLeader ? FontWeight.w800 : FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 36, child: _ValueCell('${standing.played}')),
              SizedBox(width: 36, child: _ValueCell('${standing.wins}')),
              SizedBox(width: 36, child: _ValueCell('${standing.losses}')),
              SizedBox(width: 44, child: _ValueCell(goalDifference)),
              const SizedBox(width: 8),
              _PointsCell(points: standing.points),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip circular da posição: líder em destaque primário, demais neutros.
class _PositionChip extends StatelessWidget {
  final int position;

  const _PositionChip({required this.position});

  @override
  Widget build(BuildContext context) {
    final isLeader = position == 1;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isLeader ? AppColors.primary : AppColors.grayFill,
        shape: BoxShape.circle,
      ),
      child: isLeader
          ? const Icon(Icons.emoji_events, size: 16, color: Colors.white)
          : Text(
              '$position',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  final String value;

  const _ValueCell(this.value);

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// Pontos em evidência: pílula neutra com número grande e bold.
class _PointsCell extends StatelessWidget {
  final int points;

  const _PointsCell({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.grayFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$points',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
