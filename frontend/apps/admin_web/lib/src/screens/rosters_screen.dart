import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Gestão de elencos (roster): inscreve e remove atletas de um time.
class RostersScreen extends ConsumerWidget {
  const RostersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitions = ref.watch(competitionsProvider);
    final selectedCompetition = ref.watch(selectedCompetitionProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedTeam = ref.watch(selectedTeamProvider);

    final compItems = competitions.valueOrNull ?? const [];
    final effectiveComp =
        selectedCompetition ?? (compItems.isNotEmpty ? compItems.first.id : null);
    final categories = effectiveComp == null
        ? null
        : ref.watch(categoriesProvider(effectiveComp));
    final catItems = categories?.valueOrNull ?? const [];
    final effectiveCat =
        selectedCategory ?? (catItems.isNotEmpty ? catItems.first.id : null);
    final teams = effectiveCat == null
        ? null
        : ref.watch(teamsProvider(effectiveCat));
    final teamItems = teams?.valueOrNull ?? const [];
    final effectiveTeam =
        selectedTeam ?? (teamItems.isNotEmpty ? teamItems.first.id : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elenco'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      floatingActionButton: effectiveTeam == null
          ? null
          : FloatingActionButton(
              tooltip: 'Inscrever atleta',
              onPressed: () => _showAddDialog(context, ref, effectiveTeam),
              child: const Icon(Icons.person_add_alt_1),
            ),
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
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: DropdownButtonFormField<String>(
                  initialValue: effectiveComp,
                  decoration: const InputDecoration(
                    labelText: 'Campeonato',
                    border: OutlineInputBorder(),
                  ),
                  items: compItems
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (value) {
                    ref.read(selectedCompetitionProvider.notifier).state = value;
                    ref.read(selectedCategoryProvider.notifier).state = null;
                    ref.read(selectedTeamProvider.notifier).state = null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: (categories?.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => const Text('Erro ao carregar categorias'),
                  data: (items) => DropdownButtonFormField<String>(
                    initialValue: effectiveCat,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: items
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (value) {
                      ref.read(selectedCategoryProvider.notifier).state = value;
                      ref.read(selectedTeamProvider.notifier).state = null;
                    },
                  ),
                ) ??
                const LinearProgressIndicator()),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: (teams?.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => const Text('Erro ao carregar times'),
                  data: (items) => DropdownButtonFormField<String>(
                    initialValue: effectiveTeam,
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      border: OutlineInputBorder(),
                    ),
                    items: items
                        .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                        .toList(),
                    onChanged: (value) =>
                        ref.read(selectedTeamProvider.notifier).state = value,
                  ),
                ) ??
                const LinearProgressIndicator()),
              ),
              Expanded(
                child: effectiveTeam == null
                    ? const AppEmptyState(
                        message: 'Nenhum time cadastrado',
                        icon: Icons.groups_outlined,
                      )
                    : ref.watch(rosterProvider(effectiveTeam)).when(
                        loading: () => const AppLoading(message: 'Carregando elenco...'),
                        error: (error, stackTrace) => AppErrorState(
                          message: 'Não foi possível carregar o elenco',
                          onRetry: () => ref.invalidate(rosterProvider(effectiveTeam)),
                        ),
                        data: (items) {
                          if (items.isEmpty) {
                            return const AppEmptyState(
                              message: 'Nenhum atleta inscrito',
                              icon: Icons.groups_outlined,
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final entry = items[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(entry.athleteName),
                                  subtitle: Text(
                                    '${entry.number != null ? 'Camisa ${entry.number} · ' : ''}${entry.status}',
                                  ),
                                  trailing: IconButton(
                                    tooltip: 'Remover do elenco',
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () async {
                                      await ref
                                          .read(rosterApiProvider)
                                          .remove(
                                            teamId: effectiveTeam,
                                            athleteId: entry.athleteId,
                                          );
                                      ref.invalidate(rosterProvider(effectiveTeam));
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddDialog(
      BuildContext context, WidgetRef ref, String teamId) async {
    final athletes = await ref.read(athletesProvider.future);
    if (!context.mounted) return;
    String? athleteId;
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inscrever atleta'),
        content: DropdownButtonFormField<String>(
          initialValue: null,
          decoration: const InputDecoration(
            labelText: 'Atleta',
            border: OutlineInputBorder(),
          ),
          items: athletes
              .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
              .toList(),
          onChanged: (value) => athleteId = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, athleteId != null),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (added == true && athleteId != null) {
      await ref
          .read(rosterApiProvider)
          .add(teamId: teamId, athleteId: athleteId!);
      ref.invalidate(rosterProvider(teamId));
    }
  }
}
