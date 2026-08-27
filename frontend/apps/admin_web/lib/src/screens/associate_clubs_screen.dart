import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_screen.dart';

/// Associação de clubes (organizações) a um campeonato (issue #351).
///
/// Lista todos os clubes da plataforma com busca por nome fantasia
/// ([Organization.tradeName]) e indica quais já estão inscritos no
/// campeonato selecionado (existe um [Team] com `organizationId` do clube).
/// Clubes já associados aparecem com marcação e não podem ser re-associados;
/// os demais têm o botão "Associar", que cria um [Team] via
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

  /// Clubes com associação em andamento (desabilita o botão durante o POST).
  final Set<String> _associatingOrgIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Cria o [Team] que inscreve o clube no campeonato.
  Future<void> _associate(Organization club, String competitionId) async {
    // Capturados antes do await: o contexto pode sair de cena ao trocar de tela.
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _associatingOrgIds.add(club.id));
    try {
      await ref
          .read(teamApiProvider)
          .create(
            organizationId: club.id,
            competitionId: competitionId,
            name: club.tradeName,
          );
      ref.invalidate(teamsProvider(competitionId));
      messenger.showSnackBar(
        SnackBar(content: Text('${club.tradeName} associado ao campeonato.')),
      );
    } on RepositoryException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível associar o clube.')),
      );
    } finally {
      if (mounted) setState(() => _associatingOrgIds.remove(club.id));
    }
  }

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
    final selectedCompetition = ref.watch(selectedCompetitionProvider);

    return AppScreen(
      title: 'Associar clubes',
      leading: AppBackButton(fallbackRoute: '/teams'),
      body: competitions.when(
        loading: () => const AppLoading(message: 'Carregando campeonatos...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar os campeonatos',
          onRetry: () => ref.invalidate(competitionsProvider),
        ),
        data: (compItems) {
          final effectiveComp =
              widget.lockedCompetitionId ??
              selectedCompetition ??
              (compItems.isNotEmpty ? compItems.first.id : null);

          if (effectiveComp == null) {
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
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar clube',
                      hintText: 'Busque pelo nome fantasia',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Limpar busca',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
              ),
              Expanded(child: _buildClubList(effectiveComp)),
            ],
          );
        },
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
        final associatedOrgIds = <String>{
          for (final team in teams)
            if (team.organizationId != null) team.organizationId!,
        };

        return orgsAsync.when(
          loading: () =>
              const AppLoading(message: 'Carregando organizações...'),
          error: (error, stackTrace) => AppErrorState(
            message: 'Não foi possível carregar as organizações',
            onRetry: () => ref.invalidate(organizationsProvider),
          ),
          data: (orgs) {
            if (orgs.isEmpty) {
              return const AppEmptyState(
                message: 'Nenhum clube cadastrado na plataforma',
                icon: Icons.groups_outlined,
              );
            }
            final filtered = _filter(orgs);
            if (filtered.isEmpty) {
              return AppEmptyState(
                message: 'Nenhum clube encontrado para "$_query".',
                icon: Icons.search_off,
              );
            }
            return AppLayout.content(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final club = filtered[index];
                  return _clubCard(
                    club,
                    competitionId,
                    associatedOrgIds: associatedOrgIds,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _clubCard(
    Organization club,
    String competitionId, {
    required Set<String> associatedOrgIds,
  }) {
    final isAssociated = associatedOrgIds.contains(club.id);
    final associating = _associatingOrgIds.contains(club.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
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
            if (associating)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (isAssociated)
              const _AssociatedBadge()
            else
              FilledButton(
                onPressed: () => _associate(club, competitionId),
                child: const Text('Associar'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _clubAvatar(Organization club) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          club.tradeName.isEmpty ? '?' : club.tradeName[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
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
