import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Gestão de elencos (roster): clube do usuário → elenco do clube.
///
/// O fluxo (issue #360) é: campeonato → clubes (organizações) do usuário →
/// elenco do clube. O elenco é a associação de atletas ao clube naquele
/// campeonato — não um cadastro de time. Os cardapios seguem o padrão de
/// grid da tela de atletas e navegam para `/teams/:id/roster`.
class RostersScreen extends ConsumerWidget {
  const RostersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitions = ref.watch(competitionsProvider);
    final selectedCompetition = ref.watch(selectedCompetitionProvider);

    final compItems = competitions.valueOrNull ?? const [];
    final effectiveComp =
        selectedCompetition ??
        (compItems.isNotEmpty ? compItems.first.id : null);

    return AppScreen(
      title: 'Elenco',
      leading: BackButton(onPressed: () => context.go('/')),
      body: competitions.when(
        loading: () => const AppLoading(message: 'Carregando campeonatos...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar os campeonatos',
          onRetry: () => ref.invalidate(competitionsProvider),
        ),
        data: (_) {
          if (compItems.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhum campeonato cadastrado',
              icon: Icons.emoji_events_outlined,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppLayout.content(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('comp-$effectiveComp'),
                    initialValue: effectiveComp,
                    decoration: const InputDecoration(
                      labelText: 'Campeonato',
                      border: OutlineInputBorder(),
                    ),
                    items: compItems
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      ref.read(selectedCompetitionProvider.notifier).state =
                          value;
                      ref.read(selectedTeamProvider.notifier).state = null;
                    },
                  ),
                ),
              ),
              Expanded(
                child: effectiveComp != null
                    ? _clubList(context, ref, effectiveComp)
                    : const AppEmptyState(
                        message: 'Selecione um campeonato',
                        icon: Icons.emoji_events_outlined,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Lista os clubes (organizações) do usuário que participam do campeonato.
  ///
  /// Combina [teamsProvider] (participação do clube no campeonato) com
  /// [organizationsProvider] (dados da organização). Mantém apenas os clubes
  /// cujo `createdBy` é o usuário logado e que participam do campeonato.
  Widget _clubList(
    BuildContext context,
    WidgetRef ref,
    String competitionId,
  ) {
    final teamsAsync = ref.watch(teamsProvider(competitionId));
    final orgsAsync = ref.watch(organizationsProvider);

    if (teamsAsync.isLoading || orgsAsync.isLoading) {
      return const AppLoading(message: 'Carregando clubes...');
    }
    if (teamsAsync.hasError) {
      return AppErrorState(
        message: 'Não foi possível carregar os clubes',
        onRetry: () => ref.invalidate(teamsProvider(competitionId)),
      );
    }
    if (orgsAsync.hasError) {
      return AppErrorState(
        message: 'Não foi possível carregar os clubes',
        onRetry: () => ref.invalidate(organizationsProvider),
      );
    }

    final teams = teamsAsync.value ?? const <Team>[];
    final orgs = orgsAsync.value ?? const <Organization>[];
    final userId = ref.read(authControllerProvider).state.user?.id;

    final orgById = {for (final o in orgs) o.id: o};

    // Deduplica por organização: um clube aparece uma única vez por
    // campeonato. Mantém o primeiro time como destino do elenco.
    final clubs = <_ClubEntry>[];
    final seenOrgIds = <String>{};
    for (final team in teams) {
      final orgId = team.organizationId;
      if (orgId == null || orgId.isEmpty) continue;
      if (seenOrgIds.contains(orgId)) continue;
      final org = orgById[orgId];
      if (org == null) continue;
      if (userId != null && org.createdBy != userId) continue;
      seenOrgIds.add(orgId);
      clubs.add(_ClubEntry(team: team, org: org));
    }

    if (clubs.isEmpty) {
      return const AppEmptyState(
        message: 'Nenhum clube seu neste campeonato',
        icon: Icons.groups_outlined,
      );
    }

    return AppLayout.content(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 600 ? 2 : 1;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clubs.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 96,
            ),
            itemBuilder: (context, index) => _clubCard(context, clubs[index]),
          );
        },
      ),
    );
  }

  Widget _clubCard(BuildContext context, _ClubEntry entry) {
    final org = entry.org;
    final team = entry.team;

    // Nome de exibição: razão social curta (tradeName), com fallback no nome
    // do time (participação no campeonato).
    final title = org.tradeName.isNotEmpty ? org.tradeName : team.name;
    final subtitle = [
      if (org.city != null && org.city!.isNotEmpty) org.city!,
      if (org.organizationType != null) org.organizationType!.label,
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/teams/${team.id}/roster', extra: team),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _typeIcon(org.organizationType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ícone destacado com o tipo de organização (fundo primary 12% + ícone).
  Widget _typeIcon(OrganizationType? type) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(_orgTypeIcon(type), color: AppColors.primary),
    );
  }
}

/// Ícone correspondente ao tipo de organização (issue #363).
IconData _orgTypeIcon(OrganizationType? type) => switch (type) {
      OrganizationType.federation => Icons.account_balance_outlined,
      OrganizationType.league => Icons.emoji_events_outlined,
      OrganizationType.association => Icons.groups_outlined,
      OrganizationType.university => Icons.school_outlined,
      OrganizationType.club => Icons.sports_outlined,
      OrganizationType.other => Icons.business_outlined,
      null => Icons.business_outlined,
    };

/// Par (time do campeonato + organização/clube) exibido na lista.
class _ClubEntry {
  const _ClubEntry({required this.team, required this.org});

  final Team team;
  final Organization org;
}
