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

/// Detalhe de um jogo: confronto, placar, status e informações.
class GameDetailScreen extends ConsumerWidget {
  const GameDetailScreen({super.key, this.gameId, this.game});

  final String? gameId;
  final Game? game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameFuture = game != null ? null : ref.watch(gameProvider(gameId!));

    return AppScreen(
      title: game?.homeTeamName ?? 'Jogo',
      breadcrumb: [
        const BreadcrumbItem('Início', route: '/'),
        const BreadcrumbItem(AppStrings.games, route: '/games'),
        if (game?.homeTeamName != null) BreadcrumbItem(game!.homeTeamName!),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conteúdo
          gameFuture == null
              ? _buildDetail(context, ref, game!)
              : gameFuture.when(
                  loading: () =>
                      const AppLoading(message: 'Carregando jogo...'),
                  error: (error, stackTrace) => AppErrorState(
                    message: 'Não foi possível carregar o jogo',
                    onRetry: () => ref.invalidate(gameProvider(gameId!)),
                  ),
                  data: (game) => _buildDetail(context, ref, game),
                ),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Game game) {
    // P3 #471: resolve o campeonato pelo family (autoDispose) em vez de
    // assistir a lista completa — rebuild só quando ESTA competição muda.
    final compAsync = game.competitionId != null
        ? ref.watch(competitionProvider(game.competitionId!))
        : null;
    final competitionName = compAsync?.valueOrNull?.name ?? '';
    // Issue #261: edição do jogo exige ser criador do campeonato ou ADMIN.
    final competition = compAsync?.valueOrNull;
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider.select((a) => a.state.user)),
      competition,
    );

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
                        Expanded(
                          child: Text(
                            '${game.homeTeamName ?? 'Casa'} x ${game.awayTeamName ?? 'Fora'}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                        ),
                        _statusChip(game.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (game.homeScore != null || game.awayScore != null)
                      Text(
                        'Placar: ${game.homeScore ?? 0} x ${game.awayScore ?? 0}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                    const SizedBox(height: 16),
                    if (canEdit)
                      KicksterButton(
                        label: 'Editar dados',
                        icon: Icons.edit_outlined,
                        onPressed: () => context.go(
                          '/games/${game.id}/edit',
                          extra: (roundId: game.roundId, game: game),
                        ),
                      )
                    else
                      const EditRestrictionNote(
                        message:
                            'Apenas o criador do campeonato pode editar '
                            'este jogo.',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppInfoCard(children: [
              AppInfoRow(
                label: 'Rodada',
                value: game.roundNumber?.toString() ?? '—',
              ),
              if (competitionName.isNotEmpty)
                AppInfoRow(label: 'Campeonato', value: competitionName),
              AppInfoRow(label: 'Horário', value: formatBrDateTime(game.scheduledAt)),
              if (game.venueName != null && game.venueName!.isNotEmpty)
                AppInfoRow(label: 'Campo', value: game.venueName!),
              if (game.venueAddress != null && game.venueAddress!.isNotEmpty)
                AppInfoRow(label: 'Endereço', value: game.venueAddress!),
            ]),
            const SizedBox(height: 16),
            Text(
              'Criado em ${formatBrDate(game.scheduledAt)}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
    );
  }

  Widget _statusChip(GameStatus status) {
    final (label, color) = switch (status) {
      GameStatus.scheduled => ('Agendado', AppColors.primary),
      GameStatus.open => ('Abertura', AppColors.textSecondary),
      GameStatus.inProgress => ('Ao vivo', AppColors.success),
      GameStatus.conference => ('Conferência', AppColors.textSecondary),
      GameStatus.finished => ('Encerrado', AppColors.textSecondary),
      GameStatus.cancelled => ('Cancelado', AppColors.danger),
    };
    return KicksterBadge(label: label, color: color);
  }
}
