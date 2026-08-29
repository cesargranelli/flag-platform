import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../widgets/app_screen.dart';
import '../widgets/edit_restriction_note.dart';

/// Detalhe de uma rodada: apresenta os dados e oferece a edição.
class RoundDetailScreen extends ConsumerWidget {
  const RoundDetailScreen({super.key, this.roundId, this.round});

  final String? roundId;
  final Round? round;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roundFuture = round != null ? null : ref.watch(roundProvider(roundId!));

    return AppScreen(
      title: round?.name ?? 'Rodada',
      body: roundFuture == null
          ? _buildDetail(context, ref, round!)
          : roundFuture.when(
              loading: () => const AppLoading(message: 'Carregando rodada...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar a rodada',
                onRetry: () => ref.invalidate(roundProvider(roundId!)),
              ),
              data: (round) => _buildDetail(context, ref, round),
            ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Round round) {
    final competitions = ref.watch(competitionsProvider);
    final competitionName = competitions.valueOrNull
            ?.where((c) => c.id == round.competitionId)
            .map((c) => c.name)
            .firstOrNull ??
        '';
    // Issue #261: edição da rodada exige ser criador do campeonato ou ADMIN.
    // Issue #305: e o campeonato precisa estar em DRAFT (estrutura travada
    // após a publicação).
    final competition = competitions.valueOrNull
        ?.where((c) => c.id == round.competitionId)
        .firstOrNull;
    final isDraft = competition?.status == CompetitionStatus.draft;
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider).state.user,
      competition,
    );
    final canManage = canEdit && isDraft;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppLayout.detail(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              '${round.number}',
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                round.name,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                round.type.label,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (canManage) ...[
                      FilledButton.icon(
                        onPressed: () => context.go(
                          '/rounds/${round.id}/edit',
                          extra: round,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar dados'),
                      ),
                      const SizedBox(height: 8),
                      // Issue #347: confrontos/jogos geridos via contexto do
                      // campeonato (rodada → jogos), sem atalho global da home.
                      FilledButton.icon(
                        onPressed: () {
                          ref
                                  .read(selectedCompetitionProvider.notifier)
                                  .state =
                              round.competitionId;
                          ref.read(selectedRoundProvider.notifier).state =
                              round.id;
                          context.go('/games');
                        },
                        icon: const Icon(Icons.sports),
                        label: const Text('Confrontos'),
                      ),
                    ] else
                      EditRestrictionNote(
                        message: !isDraft
                            ? 'Campeonato publicado — as rodadas estão '
                                'travadas.'
                            : 'Apenas o criador do campeonato pode editar '
                                'esta rodada.',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _infoCard([
              _row('Número', '${round.number}'),
              _row('Nome', round.name),
              _row('Tipo', round.type.label),
              _row('Campeonato', competitionName),
            ]),
            const SizedBox(height: 16),
            Text(
              'Criado em ${_formatDate(round.createdAt)}'
              '${round.updatedAt != null ? ' • Atualizado em ${_formatDate(round.updatedAt)}' : ''}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
