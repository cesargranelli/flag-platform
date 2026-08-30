import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../utils/mutation.dart';
import '../widgets/app_screen.dart';

/// Associação de clubes (organizações) a um campeonato (issue #351).
///
/// Lista todos os clubes da plataforma com busca por nome fantasia
/// ([Organization.tradeName]) e indica quais já estão inscritos no
/// campeonato selecionado (existe um [Team] com `organizationId` do clube).
/// Clubes já associados aparecem com marcação e podem ser **desassociados**
/// (issue #354), removendo o [Team] via `teamApiProvider.delete(...)`.
/// Os demais podem ser associados individualmente ("Associar") ou **em lote**,
/// selecionando vários clubes não associados via checkbox e confirmando na
/// barra de seleção, que cria um [Team] para cada um via
/// `teamApiProvider.create(...)`.
///
/// A tela fica "travada" no campeonato informado via [lockedCompetitionId]
/// (usado ao vir do detalhe do campeonato, #349); sem o valor, resolve o
/// campeonato selecionado ou o primeiro da lista.
class AssociateClubsScreen extends ConsumerStatefulWidget {
  const AssociateClubsScreen({super.key, this.lockedCompetitionId});

  final String? lockedCompetitionId;

  @override
  ConsumerState<AssociateClubsScreen> createState() =>
      _AssociateClubsScreenState();
}

class _AssociateClubsScreenState extends ConsumerState<AssociateClubsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _associateScope = 'associate-orgs';
  static const _disassociateScope = 'disassociate-teams';

  /// Ids de clubes NÃO associados marcados para associação em lote.
  final Set<String> _selectedOrgIds = {};

  /// Indica se a associação em lote está sendo executada.
  bool _submittingBatch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Cria o [Team] que inscreve o clube no campeonato.
  Future<void> _associate(Organization club, String competitionId) async {
    await runMutation(
      context,
      ref: ref,
      scope: _associateScope,
      action: () => ref
          .read(teamApiProvider)
          .associateClub(competitionId: competitionId, organizationId: club.id),
      successMessage: '${club.tradeName} associado ao campeonato.',
      errorMessage: 'Não foi possível associar o clube.',
      progressId: club.id,
      onSuccess: () => ref.invalidate(teamsProvider(competitionId)),
    );
  }

  /// Remove a inscrição do clube no campeonato (desassociar).
  Future<void> _disassociate(Team team, String competitionId) async {
    await runMutation(
      context,
      ref: ref,
      scope: _disassociateScope,
      action: () => ref.read(teamApiProvider).delete(team.id),
      successMessage: 'Clube desassociado do campeonato.',
      errorMessage: 'Não foi possível desassociar o clube.',
      progressId: team.id,
      onSuccess: () {
        ref.invalidate(teamsProvider(competitionId));
        // O clube deixou de ser selecionável; remove da seleção se constar.
        if (team.organizationId != null && mounted) {
          setState(() => _selectedOrgIds.remove(team.organizationId));
        }
      },
    );
  }

  /// Associa em lote todos os clubes selecionados (cria um [Team] por clube).
  ///
  /// Cada falha é tratada isoladamente — o lote não é abortado. Ao final
  /// exibe um SnackBar-resumo e invalida [teamsProvider].
  Future<void> _associateSelected(
    String competitionId,
    Map<String, Organization> orgsById,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ids = List<String>.from(_selectedOrgIds);
    if (ids.isEmpty) return;

    setState(() => _submittingBatch = true);
    var success = 0;
    var failure = 0;
    for (final orgId in ids) {
      final club = orgsById[orgId];
      if (club == null) continue;
      try {
        await ref
            .read(teamApiProvider)
            .associateClub(
              competitionId: competitionId,
              organizationId: club.id,
            );
        success++;
      } catch (_) {
        failure++;
      }
    }

    if (mounted) {
      setState(() {
        _selectedOrgIds.clear();
        _submittingBatch = false;
      });
    }
    // Revalida os times (clubes recém-associados deixam de ser selecionáveis).
    ref.invalidate(teamsProvider(competitionId));

    final summary = [
      if (success > 0) '$success associado(s)',
      if (failure > 0) '$failure falha(s)',
    ].join('; ');
    messenger.showSnackBar(SnackBar(content: Text('$summary.')));
  }

  /// Tipos de organização que podem ser associados como clube (#357):
  /// clubes e universidades/colégios.
  bool _isAssociableType(Organization org) =>
      org.organizationType == OrganizationType.club ||
      org.organizationType == OrganizationType.university;

  List<Organization> _filter(List<Organization> orgs) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return orgs;
    return orgs
        .where((o) => o.tradeName.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);

    return AppScreen(
      title: 'Associar clubes',
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem(AppStrings.teams, route: '/teams'),
        BreadcrumbItem('Associar clubes'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conteúdo (Expanded para dar altura finita à lista lazy)
          Expanded(
            child: competitions.when(
              loading: () =>
                  const AppLoading(message: 'Carregando campeonatos...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar os campeonatos',
                onRetry: () => ref.invalidate(competitionsProvider),
              ),
              data: (compItems) {
                // P4 #461: locked (rota) ?? efetivo (selecionado ?? primeiro).
                final effectiveComp =
                    widget.lockedCompetitionId ??
                    ref.watch(effectiveCompetitionProvider);

                if (effectiveComp == null) {
                  return KicksterEmptyState(
                    icon: Icons.emoji_events_outlined,
                    message: 'Nenhum campeonato cadastrado',
                    description:
                        'Crie um campeonato para associar clubes a ele.',
                    action: KicksterButton(
                      label: 'Criar campeonato',
                      icon: Icons.add,
                      onPressed: () => context.go('/competitions/new'),
                    ),
                  );
                }

                // Issue #357: largura padrão dos formulários (600px), como nas
                // telas de cadastro de organizações/campeonatos.
                return AppLayout.form(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: KicksterSearchField(
                          controller: _searchController,
                          onChanged: (value) => setState(() {
                            _query = value;
                            // A seleção pode conter clubes que saíram do filtro;
                            // limpa para evitar seleções "fantasma".
                            _selectedOrgIds.clear();
                          }),
                          hint: 'Buscar clube',
                        ),
                      ),
                      // Lista em altura finita (Expanded) → virtualização real.
                      Expanded(
                        child: _buildClubList(effectiveComp),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubList(String competitionId) {
    final orgsAsync = ref.watch(organizationsProvider);
    final teamsAsync = ref.watch(teamsProvider(competitionId));

    return teamsAsync.when(
      loading: () => const AppLoading(message: 'Carregando clubes...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Não foi possível carregar os clubes',
        onRetry: () => ref.invalidate(teamsProvider(competitionId)),
      ),
      data: (teams) {
        // Organizações já inscritas neste campeonato (id do clube → Team).
        final orgIdToTeam = <String, Team>{
          for (final team in teams)
            if (team.organizationId != null) team.organizationId!: team,
        };

        return orgsAsync.when(
          loading: () =>
              const AppLoading(message: 'Carregando organizações...'),
          error: (error, stackTrace) => AppErrorState(
            message: 'Não foi possível carregar as organizações',
            onRetry: () => ref.invalidate(organizationsProvider),
          ),
          data: (orgs) {
            // Issue #357: apenas clubes e universidades/colégios são
            // associáveis nesta tela.
            final clubs = orgs.where(_isAssociableType).toList();
            if (clubs.isEmpty) {
              return KicksterEmptyState(
                icon: Icons.groups_outlined,
                message: 'Nenhum clube/universidade disponível',
                description:
                    'Crie a organização clube/universidade para associá-la '
                    'ao campeonato.',
                action: KicksterButton(
                  label: 'Criar organização',
                  icon: Icons.add,
                  onPressed: () => context.go('/organizations/new'),
                ),
              );
            }
            final filtered = _filter(clubs);
            if (filtered.isEmpty) {
              return AppEmptyState(
                message: 'Nenhum clube encontrado para "$_query".',
                icon: Icons.search_off,
              );
            }

            final orgsById = {for (final o in clubs) o.id: o};
            final hasSelectable = filtered.any(
              (o) => !orgIdToTeam.containsKey(o.id),
            );

            return Column(
              children: [
                if (hasSelectable) _selectionBar(competitionId, orgsById),
                // Lista em altura finita (Expanded) → virtualização real (lazy).
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final club = filtered[index];
                      return _clubCard(
                        club,
                        competitionId,
                        orgIdToTeam: orgIdToTeam,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Barra fixa de seleção em lote: contador + botão "Associar selecionados".
  Widget _selectionBar(
    String competitionId,
    Map<String, Organization> orgsById,
  ) {
    final count = _selectedOrgIds.length;
    return Material(
      color: AppColors.surfaceMuted,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                count == 0
                    ? 'Selecione clubes para associar em lote'
                    : '$count clube(s) selecionado(s)',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            KicksterButton(
              label: 'Associar selecionados ($count)',
              onPressed: count == 0 || _submittingBatch
                  ? null
                  : () => _associateSelected(competitionId, orgsById),
              loading: _submittingBatch,
            ),
          ],
        ),
      ),
    );
  }

  Widget _clubCard(
    Organization club,
    String competitionId, {
    required Map<String, Team> orgIdToTeam,
  }) {
    final team = orgIdToTeam[club.id];
    final isAssociated = team != null;
    final associating =
        ref.watch(mutationProgressProvider(_associateScope)).contains(club.id);
    final disassociating = team != null &&
        ref
            .watch(mutationProgressProvider(_disassociateScope))
            .contains(team.id);
    final selected = _selectedOrgIds.contains(club.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Apenas clubes não associados são selecionáveis para o lote.
            if (!isAssociated)
              Checkbox(
                value: selected,
                onChanged: associating || _submittingBatch
                    ? null
                    : (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedOrgIds.add(club.id);
                          } else {
                            _selectedOrgIds.remove(club.id);
                          }
                        });
                      },
              ),
            _clubAvatar(club),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club.tradeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (club.city != null && club.city!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      club.city!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _clubAction(
              club: club,
              competitionId: competitionId,
              team: team,
              isAssociated: isAssociated,
              associating: associating,
              disassociating: disassociating,
            ),
          ],
        ),
      ),
    );
  }

  /// Ação à direita do card: spinner durante POST/DELETE, badge + "Desassociar"
  /// para clubes associados ou botão "Associar" para os demais.
  Widget _clubAction({
    required Organization club,
    required String competitionId,
    required Team? team,
    required bool isAssociated,
    required bool associating,
    required bool disassociating,
  }) {
    if (associating || disassociating) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (isAssociated) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _AssociatedBadge(),
          IconButton(
            tooltip: 'Desassociar',
            icon: const Icon(Icons.link_off),
            onPressed: _submittingBatch
                ? null
                : () => _disassociate(team!, competitionId),
          ),
        ],
      );
    }
    return KicksterButton(
      label: 'Associar',
      onPressed: _submittingBatch
          ? null
          : () => _associate(club, competitionId),
    );
  }

  Widget _clubAvatar(Organization club) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        organizationTypeIcon(club.organizationType),
        color: AppColors.primary,
      ),
    );
  }
}

/// Marcação visual de clube já associado (não permite re-associar).
class _AssociatedBadge extends StatelessWidget {
  const _AssociatedBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 20),
        const SizedBox(width: 6),
        Text(
          'Associado',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}
