import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Gestão de categorias: lista por campeonato e acesso ao formulário.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitions = ref.watch(competitionsProvider);
    final selected = ref.watch(selectedCompetitionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      floatingActionButton: competitions.valueOrNull?.isNotEmpty == true
          ? FloatingActionButton(
              tooltip: 'Nova categoria',
              onPressed: () => context.push('/categories/new'),
              child: const Icon(Icons.add),
            )
          : null,
      body: competitions.when(
        loading: () => const AppLoading(message: 'Carregando campeonatos...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar os campeonatos',
          onRetry: () => ref.invalidate(competitionsProvider),
        ),
        data: (compItems) {
          if (compItems.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhum campeonato cadastrado',
              icon: Icons.emoji_events_outlined,
            );
          }
          final effectiveSelected = selected ?? compItems.first.id;
          final categories = ref.watch(categoriesProvider(effectiveSelected));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  initialValue: effectiveSelected,
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
                  onChanged: (value) =>
                      ref.read(selectedCompetitionProvider.notifier).state = value,
                ),
              ),
              Expanded(
                child: categories.when(
                  loading: () => const AppLoading(message: 'Carregando categorias...'),
                  error: (error, stackTrace) => AppErrorState(
                    message: 'Não foi possível carregar as categorias',
                    onRetry: () =>
                        ref.invalidate(categoriesProvider(effectiveSelected)),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const AppEmptyState(
                        message: 'Nenhuma categoria cadastrada',
                        icon: Icons.category_outlined,
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final category = items[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(category.name),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(
                              '/categories/${category.id}',
                              extra: category,
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
}
