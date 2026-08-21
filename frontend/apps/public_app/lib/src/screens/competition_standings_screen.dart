import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Tela de classificação de um campeonato (issue #27).
///
/// Exibe a tabela (posição, time, PJ, V, D, SG, PTS) do campeonato, com
/// destaque para o líder e atualização via pull to refresh. No fluxo único
/// (migração V24) a classificação é por campeonato — não há mais categorias.
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
    final title = competitionName.isEmpty ? 'Classificação' : competitionName;
    final standingsAsync = ref.watch(
      competitionStandingsProvider(competitionId),
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
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
        borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 16),
          SizedBox(width: 28, child: Text('Pos', style: _headerStyle)),
          Expanded(child: Text('Time', style: _headerStyle)),
          SizedBox(width: 40, child: _HeaderCell('PJ')),
          SizedBox(width: 40, child: _HeaderCell('V')),
          SizedBox(width: 40, child: _HeaderCell('D')),
          SizedBox(width: 48, child: _HeaderCell('SG')),
          SizedBox(width: 48, child: _HeaderCell('PTS')),
          SizedBox(width: 12),
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

/// Linha de uma posição na tabela; o líder ganha destaque visual.
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

    return Container(
      decoration: BoxDecoration(
        color: isLeader ? AppColors.primary.withValues(alpha: 0.06) : null,
        border: Border(
          top: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.15),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 16),
          SizedBox(
            width: 28,
            child: isLeader
                ? const Icon(
                    Icons.emoji_events,
                    size: 18,
                    color: AppColors.primary,
                  )
                : Text(
                    '${standing.position}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
          Expanded(
            child: Text(
              teamLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isLeader ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: 40, child: _ValueCell('${standing.played}')),
          SizedBox(width: 40, child: _ValueCell('${standing.wins}')),
          SizedBox(width: 40, child: _ValueCell('${standing.losses}')),
          SizedBox(width: 48, child: _ValueCell(goalDifference)),
          SizedBox(
            width: 48,
            child: _ValueCell('${standing.points}', bold: isLeader),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  final String value;
  final bool bold;

  const _ValueCell(this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: AppColors.textPrimary,
      ),
    );
  }
}
