import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Gestão de elencos (roster): clube ou universidade do usuário → elenco da
/// organização.
///
/// O fluxo (issue #360) é: campeonato → clubes/universidades (organizações)
/// do usuário → elenco da organização. A lista passa a exibir **todas** as
/// organizações clube/universidade do usuário (issue #381) — mesmo as que
/// ainda não participam do campeonato selecionado: nesse caso o card oferece
/// a ação "Associar à temporada" (cria o [Team] via `associateClub`). Os cards
/// seguem o padrão de grid da tela de atletas e navegam para
/// `/teams/:id/roster` quando o time (clube+competição) já existe.
class RostersScreen extends ConsumerStatefulWidget {
  const RostersScreen({super.key});

  @override
  ConsumerState<RostersScreen> createState() => _RostersScreenState();
}

class _RostersScreenState extends ConsumerState<RostersScreen> {
  /// Ids de organizações com associação à temporada em andamento
  /// (desabilita o card durante o POST).
  final Set<String> _associatingOrgIds = {};
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);
    final selectedCompetition = ref.watch(selectedCompetitionProvider);

    final compItems = competitions.valueOrNull ?? const [];
    final effectiveComp =
        selectedCompetition ??
        (compItems.isNotEmpty ? compItems.first.id : null);

    return AppScreen(
      title: 'Elencos',
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
              AppLayout.form(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: KicksterDropdown<String>(
                    key: ValueKey('comp-$effectiveComp'),
                    label: 'Campeonato',
                    value: effectiveComp,
                    items: compItems
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: appDropdownItem(
                              Icons.emoji_events_outlined,
                              c.name,
                            ),
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
                    ? _clubList(context, effectiveComp)
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

  /// Lista os clubes e universidades (organizações).
  ///
  /// Percorre [organizationsProvider] mantendo as elegíveis (tipo `null`,
  /// `club` ou `university` — ignora apenas os tipos explicitamente excluídos:
  /// federação/liga/associação/outro). Não filtra por `createdBy` para garantir
  /// que os clubes/universidades apareçam (#385). Para cada organização,
  /// localiza o [Team] (se houver) no campeonato via [teamsProvider].
  Widget _clubList(BuildContext context, String competitionId) {
    final teamsAsync = ref.watch(teamsProvider(competitionId));
    final orgsAsync = ref.watch(organizationsProvider);

    if (orgsAsync.isLoading) {
      return const AppLoading(message: 'Carregando clubes e universidades...');
    }
    if (orgsAsync.hasError) {
      return AppErrorState(
        message: 'Não foi possível carregar os clubes',
        onRetry: () => ref.invalidate(organizationsProvider),
      );
    }

    final orgs = orgsAsync.value ?? const <Organization>[];
    final teams = teamsAsync.value ?? const <Team>[];

    // Mapa organização → time no campeonato selecionado.
    final teamByOrgId = <String, Team>{
      for (final team in teams)
        if (team.organizationId != null) team.organizationId!: team,
    };

    // Deduplica por organização: um clube/universidade aparece uma única vez.
    // Elegível = tipo null, club ou university (ignora apenas os tipos
    // explicitamente excluídos) — #385.
    final clubs = <Organization>[];
    final seenOrgIds = <String>{};
    for (final org in orgs) {
      final type = org.organizationType;
      if (type != null &&
          type != OrganizationType.club &&
          type != OrganizationType.university) {
        continue;
      }
      if (seenOrgIds.contains(org.id)) continue;
      seenOrgIds.add(org.id);
      clubs.add(org);
    }

    if (clubs.isEmpty) {
      return KicksterEmptyState(
        icon: Icons.groups_outlined,
        message: 'Nenhum clube ou universidade seu cadastrado na plataforma',
        description: 'Crie a organização clube/universidade para começar.',
        action: KicksterButton(
          label: 'Criar organização',
          icon: Icons.add,
          onPressed: () => context.go('/organizations/new'),
        ),
      );
    }

    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? clubs
        : clubs
            .where(
              (c) =>
                  c.tradeName.toLowerCase().contains(query) ||
                  (c.city ?? '').toLowerCase().contains(query),
            )
            .toList(growable: false);

    return AppLayout.content(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                if (query.isNotEmpty)
                  Text(
                    '${filtered.length} ${filtered.length == 1 ? 'resultado' : 'resultados'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  Text(
                    '${clubs.length} '
                    '${clubs.length == 1 ? 'clube' : 'clubes e universidades'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: 280,
                  child: KicksterSearchField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const AppEmptyState(
                    message: 'Nenhum clube encontrado',
                    icon: Icons.search_off,
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 600 ? 2 : 1;
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 96,
                        ),
                        itemBuilder: (context, index) {
                          final org = filtered[index];
                          return _clubCard(
                            context,
                            org,
                            team: teamByOrgId[org.id],
                            competitionId: competitionId,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _clubCard(
    BuildContext context,
    Organization org, {
    required Team? team,
    required String competitionId,
  }) {
    final subtitle = [
      if (org.city != null && org.city!.isNotEmpty) org.city!,
      if (org.organizationType != null) org.organizationType!.label,
    ].join(' · ');

    final associating = _associatingOrgIds.contains(org.id);
    final isAssociated = team != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _handleCardTap(org, team, competitionId),
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                      org.tradeName,
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
              if (!isAssociated) ...[
                const SizedBox(width: 8),
                associating
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : FilledButton(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(0, 36),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _associate(org, competitionId),
                        child: const Text('Associar à temporada'),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Tocar no card: com time no campeonato → elenco; sem time → associa à
  /// temporada.
  void _handleCardTap(Organization org, Team? team, String competitionId) {
    final associated = team;
    if (associated != null) {
      context.go('/teams/${associated.id}/roster', extra: associated);
    } else {
      _associate(org, competitionId);
    }
  }

  /// Associa o clube/universidade à temporada selecionada (cria o [Team] via
  /// `associateClub`), revalida [teamsProvider] e navega para o elenco.
  Future<void> _associate(Organization org, String competitionId) async {
    // Capturados antes do await: o contexto pode sair de cena ao trocar de tela.
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _associatingOrgIds.add(org.id));
    try {
      final team = await ref.read(teamApiProvider).associateClub(
        competitionId: competitionId,
        organizationId: org.id,
      );
      ref.invalidate(teamsProvider(competitionId));
      messenger.showSnackBar(
        SnackBar(
          content: Text('${org.tradeName} associado à temporada.'),
        ),
      );
      if (mounted) {
        context.go('/teams/${team.id}/roster', extra: team);
      }
    } on RepositoryException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível associar o clube.')),
      );
    } finally {
      if (mounted) setState(() => _associatingOrgIds.remove(org.id));
    }
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
      child: Icon(organizationTypeIcon(type), color: AppColors.primary),
    );
  }
}
