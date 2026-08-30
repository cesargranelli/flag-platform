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
      breadcrumb: [
        const BreadcrumbItem('Início', route: '/'),
        const BreadcrumbItem(AppStrings.teams, route: '/teams'),
        if (team?.name != null) BreadcrumbItem(team!.name),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conteúdo
          teamFuture == null
              ? _buildDetail(context, ref, team!)
              : teamFuture.when(
                  loading: () =>
                      const AppLoading(message: 'Carregando time...'),
                  error: (error, stackTrace) => AppErrorState(
                    message: 'Não foi possível carregar o time',
                    onRetry: () => ref.invalidate(teamProvider(teamId!)),
                  ),
                  data: (team) => _buildDetail(context, ref, team),
                ),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Team team) {
    // P3 #471: resolve o campeonato pelo family (autoDispose) em vez de
    // assistir a lista completa.
    final compAsync = ref.watch(competitionProvider(team.competitionId));
    final competitionName = compAsync.valueOrNull?.name ?? '';
    final divisions = ref.watch(divisionsProvider(team.competitionId));
    final divisionName =
        divisions.valueOrNull
            ?.where((d) => d.id == team.divisionId)
            .map((d) => d.name)
            .firstOrNull ??
        '';
    // Issue #261: edição do time exige ser criador do campeonato ou ADMIN.
    final competition = compAsync.valueOrNull;
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
                        _avatar(team, size: 64, radius: 16),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
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
                      KicksterButton(
                        label: 'Editar dados',
                        icon: Icons.edit_outlined,
                        onPressed: () =>
                            context.go('/teams/${team.id}/edit', extra: team),
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
            AppInfoCard(children: [
              AppInfoRow(label: 'Nome', value: team.name),
              AppInfoRow(
                label: 'Sigla',
                value: team.shortName?.isNotEmpty == true ? team.shortName! : '—',
              ),
              AppInfoRow(label: 'Competição', value: competitionName),
              AppInfoRow(label: 'Divisão', value: divisionName),
              if (team.logoUrl != null && team.logoUrl!.isNotEmpty)
                AppInfoRow(label: 'URL do logo', value: team.logoUrl!),
            ]),
            const SizedBox(height: 16),
            Text(
              'Criado em ${formatBrDate(team.createdAt)}'
              '${team.updatedAt != null ? ' • Atualizado em ${formatBrDate(team.updatedAt)}' : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
}
