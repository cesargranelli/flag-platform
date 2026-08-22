import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../widgets/edit_restriction_note.dart';

/// Gestão de elencos (roster): inscreve e remove atletas de um time.
///
/// O fluxo agora é: campeonato → times → elenco.
/// Os times associam-se diretamente ao competition_id (migração V24);
/// as categories foram removidas.
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

    // Issue #261: inscrição/importação de elenco exige ser criador do
    // campeonato ou ADMIN (o backend já bloqueia as escritas).
    final selectedCompetitionObj = compItems
        .where((c) => c.id == effectiveComp)
        .firstOrNull;
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider).state.user,
      selectedCompetitionObj,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elenco'),
        leading: BackButton(onPressed: () => context.go('/')),
        actions: [
          if (effectiveComp != null && canEdit)
            IconButton(
              tooltip: 'Importar CSV',
              icon: const Icon(Icons.upload_file),
              onPressed: () =>
                  context.push('/rosters/import', extra: effectiveComp),
            ),
        ],
      ),
      floatingActionButton:
          effectiveComp != null && canEdit
              ? FloatingActionButton(
                  tooltip: 'Inscrever atleta',
                  onPressed: () => context.push(
                    '/teams/new',
                    extra: (competitionId: effectiveComp),
                  ),
                  child: const Icon(Icons.person_add_alt_1),
                )
              : null,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
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
                      if (!canEdit)
                        const EditRestrictionNote(
                          message:
                              'Apenas o criador do campeonato pode '
                              'gerenciar o elenco.',
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: effectiveComp != null
                    ? ref
                          .watch(teamsProvider(effectiveComp))
                          .when(
                            loading: () => const AppLoading(
                              message: 'Carregando times...',
                            ),
                            error: (error, stackTrace) => AppErrorState(
                              message: 'Não foi possível carregar os times',
                              onRetry: () =>
                                  ref.invalidate(teamsProvider(effectiveComp)),
                            ),
                            data: (items) {
                              if (items.isEmpty) {
                                return const AppEmptyState(
                                  message: 'Nenhum time cadastrado',
                                  icon: Icons.groups_outlined,
                                );
                              }
                              return AppLayout.content(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final columns = constraints.maxWidth >= 600
                                        ? 2
                                        : 1;
                                    return GridView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: items.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: columns,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            mainAxisExtent: 96,
                                          ),
                                      itemBuilder: (context, index) {
                                        final team = items[index];
                                        return _teamCard(
                                          context,
                                          ref,
                                          team,
                                          teamId: team.id,
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          )
                    : const AppEmptyState(
                        message: 'Nenhum time cadastrado',
                        icon: Icons.groups_outlined,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _teamCard(
    BuildContext context,
    WidgetRef ref,
    Team team, {
    required String teamId,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  team.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    team.sportName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${team.athleteCount ?? 0} atletas',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
