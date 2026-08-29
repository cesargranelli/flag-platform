import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../widgets/app_screen.dart';
import '../widgets/edit_restriction_note.dart';

/// Detalhe de um jogo: confronto, placar, status e informações.
class GameDetailScreen extends ConsumerWidget {
  const GameDetailScreen({super.key, this.gameId, this.game, this.args});

  final String? gameId;
  final Game? game;

  /// Argumentos de navegação para a edição.
  final ({String? roundId, Game? game})? args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameFuture = game != null ? null : ref.watch(gameProvider(gameId!));

    return AppScreen(
      title: game?.homeTeamName ?? 'Jogo',
      backTarget: '/games',
      backLabel: 'Jogos',
      body: gameFuture == null
          ? _buildDetail(context, ref, game!)
          : gameFuture.when(
              loading: () => const AppLoading(message: 'Carregando jogo...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar o jogo',
                onRetry: () => ref.invalidate(gameProvider(gameId!)),
              ),
              data: (game) => _buildDetail(context, ref, game),
            ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Game game) {
    final competitions = ref.watch(competitionsProvider);
    final competitionName = competitions.valueOrNull
            ?.where((c) => c.id == game.competitionId)
            .map((c) => c.name)
            .firstOrNull ??
        '';
    // Issue #261: edição do jogo exige ser criador do campeonato ou ADMIN.
    final competition = competitions.valueOrNull
        ?.where((c) => c.id == game.competitionId)
        .firstOrNull;
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider).state.user,
      competition,
    );

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
                        Expanded(
                          child: Text(
                            '${game.homeTeamName ?? 'Casa'} x ${game.awayTeamName ?? 'Fora'}',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
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
                      FilledButton.icon(
                        onPressed: () => context.go(
                          '/games/${game.id}/edit',
                          extra: (roundId: game.roundId, game: game),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar dados'),
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
            _infoCard(
              'Informações',
              [
                _row('Rodada', game.roundNumber?.toString() ?? '—'),
                if (competitionName.isNotEmpty) _row('Campeonato', competitionName),
                _row('Horário', _formatDateTime(game.scheduledAt)),
                if (game.venueName != null && game.venueName!.isNotEmpty)
                  _row('Campo', game.venueName!),
                if (game.venueAddress != null && game.venueAddress!.isNotEmpty)
                  _row('Endereço', game.venueAddress!),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Criado em ${_formatDate(game.scheduledAt)}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
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

  Widget _statusChip(GameStatus status) {
    final (label, color) = switch (status) {
      GameStatus.scheduled => ('Agendado', AppColors.textSecondary),
      GameStatus.inProgress => ('Ao vivo', AppColors.success),
      GameStatus.finished => ('Encerrado', AppColors.danger),
      GameStatus.cancelled => ('Cancelado', AppColors.disabled),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, color: color),
      ),
    );
  }

  String _formatDateTime(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}