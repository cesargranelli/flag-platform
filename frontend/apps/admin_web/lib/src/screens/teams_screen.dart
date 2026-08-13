import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Gestão de times: lista por categoria e acesso ao formulário.
class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitions = ref.watch(competitionsProvider);
    final selectedCompetition = ref.watch(selectedCompetitionProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    final compItems = competitions.valueOrNull ?? const [];
    final effectiveComp =
        selectedCompetition ?? (compItems.isNotEmpty ? compItems.first.id : null);
    final categories = effectiveComp == null
        ? null
        : ref.watch(categoriesProvider(effectiveComp));
    final catItems = categories?.valueOrNull ?? const [];
    final effectiveCat =
        selectedCategory ?? (catItems.isNotEmpty ? catItems.first.id : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Times')),
      floatingActionButton: effectiveCat == null
          ? null
          : FloatingActionButton(
              tooltip: 'Novo time',
              onPressed: () => context.push('/teams/new', extra: effectiveCat),
              child: const Icon(Icons.add),
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
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    ref.read(selectedCompetitionProvider.notifier).state = value;
                    ref.read(selectedCategoryProvider.notifier).state = null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: categories!.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => const Text('Erro ao carregar categorias'),
                  data: (items) => DropdownButtonFormField<String>(
                    initialValue: effectiveCat,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: items
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        ref.read(selectedCategoryProvider.notifier).state = value,
                  ),
                ),
              ),
              Expanded(
                child: effectiveCat == null
                    ? const AppEmptyState(
                        message: 'Nenhuma categoria cadastrada',
                        icon: Icons.category_outlined,
                      )
                    : ref.watch(teamsProvider(effectiveCat)).when(
                        loading: () => const AppLoading(message: 'Carregando times...'),
                        error: (error, stackTrace) => AppErrorState(
                          message: 'Não foi possível carregar os times',
                          onRetry: () => ref.invalidate(teamsProvider(effectiveCat)),
                        ),
                        data: (items) {
                          if (items.isEmpty) {
                            return const AppEmptyState(
                              message: 'Nenhum time cadastrado',
                              icon: Icons.groups_outlined,
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final team = items[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(team.name),
                                  subtitle: Text(team.shortName ?? ''),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () =>
                                      context.push('/teams/${team.id}', extra: team),
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
}
