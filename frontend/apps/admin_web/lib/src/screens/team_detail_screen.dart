import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../widgets/app_screen.dart';
import '../widgets/edit_restriction_note.dart';

/// Detalhe de um time: apresenta os dados e oferece a edição.
class TeamDetailScreen extends ConsumerWidget {
  const TeamDetailScreen({super.key, this.teamId, this.team});

  final String? teamId;
  final Team? team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamFuture = team != null ? null : ref.watch(teamProvider(teamId!));

    return AppScreen(
      title: team?.name ?? 'Time',
      backTarget: '/teams',
      backLabel: 'Times',
      body: teamFuture == null
          ? _buildDetail(context, ref, team!)
          : teamFuture.when(
              loading: () => const AppLoading(message: 'Carregando time...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar o time',
                onRetry: () => ref.invalidate(teamProvider(teamId!)),
              ),
              data: (team) => _buildDetail(context, ref, team),
            ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Team team) {
    final competitions = ref.watch(competitionsProvider);
    final competitionName =
        competitions.valueOrNull
            ?.where((c) => c.id == team.competitionId)
            .map((c) => c.name)
            .firstOrNull ??
        '';
    final divisions = ref.watch(divisionsProvider(team.competitionId));
    final divisionName =
        divisions.valueOrNull
            ?.where((d) => d.id == team.divisionId)
            .map((d) => d.name)
            .firstOrNull ??
        '';
    // Issue #261: edição do time exige ser criador do campeonato ou ADMIN.
    final competition = competitions.valueOrNull
        ?.where((c) => c.id == team.competitionId)
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
                        _avatar(team, size: 64, radius: 16),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (team.shortName != null &&
                                  team.shortName!.isNotEmpty)
                                Text(
                                  team.shortName!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (canEdit)
                      FilledButton.icon(
                        onPressed: () =>
                            context.go('/teams/${team.id}/edit', extra: team),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar dados'),
                      )
                    else
                      const EditRestrictionNote(
                        message:
                            'Apenas o criador do campeonato pode editar '
                            'este time.',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _infoCard('Informações', [
              _row('Nome', team.name),
              _row(
                'Sigla',
                team.shortName?.isNotEmpty == true ? team.shortName! : '—',
              ),
              _row('Competição', competitionName),
              _row('Divisão', divisionName),
              if (team.logoUrl != null && team.logoUrl!.isNotEmpty)
                _row('URL do logo', team.logoUrl!),
            ]),
            const SizedBox(height: 16),
            Text(
              'Criado em ${_formatDate(team.createdAt)}'
              '${team.updatedAt != null ? ' • Atualizado em ${_formatDate(team.updatedAt)}' : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(Team team, {required double size, required double radius}) {
    final logo = team.logoUrl;
    final validLogo =
        logo != null &&
        logo.isNotEmpty &&
        (Uri.tryParse(logo)?.hasScheme ?? false);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: validLogo
          ? Image.network(
              logo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.groups_outlined,
                color: AppColors.primary,
                size: 32,
              ),
            )
          : const Icon(
              Icons.groups_outlined,
              color: AppColors.primary,
              size: 32,
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
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
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
