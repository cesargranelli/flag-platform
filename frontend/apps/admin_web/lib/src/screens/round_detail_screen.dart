import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../utils/date_formats.dart';
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
      breadcrumb: [
        const BreadcrumbItem('Início', route: '/'),
        const BreadcrumbItem(AppStrings.rounds, route: '/rounds'),
        if (round?.name != null) BreadcrumbItem(round!.name),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conteúdo
          roundFuture == null
              ? _buildDetail(context, ref, round!)
              : roundFuture.when(
                  loading: () =>
                      const AppLoading(message: 'Carregando rodada...'),
                  error: (error, stackTrace) => AppErrorState(
                    message: 'Não foi possível carregar a rodada',
                    onRetry: () => ref.invalidate(roundProvider(roundId!)),
                  ),
                  data: (round) => _buildDetail(context, ref, round),
                ),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Round round) {
    // P3 #471: resolve o campeonato pelo family (autoDispose) em vez de
    // assistir a lista completa.
    final compAsync = ref.watch(competitionProvider(round.competitionId));
    final competitionName = compAsync.valueOrNull?.name ?? '';
    // Issue #261: edição da rodada exige ser criador do campeonato ou ADMIN.
    // Issue #305: e o campeonato precisa estar em DRAFT (estrutura travada
    // após a publicação).
    final competition = compAsync.valueOrNull;
    final isDraft = competition?.status == CompetitionStatus.draft;
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider.select((a) => a.state.user)),
      competition,
    );
    final canManage = canEdit && isDraft;

    return AppLayout.detail(
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
                                  fontWeight: FontWeight.w700,
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
                                    fontSize: 20, fontWeight: FontWeight.w700),
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
                      KicksterButton(
                        label: 'Editar dados',
                        icon: Icons.edit_outlined,
                        onPressed: () => context.go(
                          '/rounds/${round.id}/edit',
                          extra: round,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Issue #347: confrontos/jogos geridos via contexto do
                      // campeonato (rodada → jogos), sem atalho global da home.
                      KicksterButton(
                        label: 'Confrontos',
                        icon: Icons.sports,
                        variant: KicksterButtonVariant.outline,
                        onPressed: () {
                          ref
                                  .read(selectedCompetitionProvider.notifier)
                                  .state =
                              round.competitionId;
                          ref.read(selectedRoundProvider.notifier).state =
                              round.id;
                          context.go('/games');
                        },
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
            AppInfoCard(children: [
              AppInfoRow(label: 'Número', value: '${round.number}'),
              AppInfoRow(label: 'Nome', value: round.name),
              AppInfoRow(label: 'Tipo', value: round.type.label),
              AppInfoRow(label: 'Campeonato', value: competitionName),
            ]),
            const SizedBox(height: 16),
            Text(
              'Criado em ${formatBrDate(round.createdAt)}'
              '${round.updatedAt != null ? ' • Atualizado em ${formatBrDate(round.updatedAt)}' : ''}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
    );
  }
}
