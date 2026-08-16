import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Gestão de categorias: cards por campeonato e acesso ao detalhe.
///
/// O seletor de campeonato (chips) define o contexto da listagem; clicar em
/// uma categoria navega para o detalhe.
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppLayout.content(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
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
                        onChanged: (value) => ref
                            .read(selectedCompetitionProvider.notifier)
                            .state = value,
                      ),
                      const SizedBox(height: 12),
                      categories.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stackTrace) => AppErrorState(
                          message: 'Não foi possível carregar as categorias',
                          onRetry: () => ref
                              .invalidate(categoriesProvider(effectiveSelected)),
                        ),
                        data: (items) {
                          if (items.isEmpty) {
                            return const AppEmptyState(
                              message: 'Nenhuma categoria cadastrada',
                              icon: Icons.category_outlined,
                            );
                          }
                          return Text(
                            '${items.length} ${items.length == 1 ? 'categoria' : 'categorias'}',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: AppLayout.content(
                  child: categories.when(
                    loading: () => const AppLoading(
                        message: 'Carregando categorias...'),
                    error: (error, stackTrace) => AppErrorState(
                      message: 'Não foi possível carregar as categorias',
                      onRetry: () => ref
                          .invalidate(categoriesProvider(effectiveSelected)),
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return const AppEmptyState(
                          message: 'Nenhuma categoria cadastrada',
                          icon: Icons.category_outlined,
                        );
                      }
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 600 ? 2 : 1;
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
                              final category = items[index];
                              return _categoryCard(context, category);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _categoryCard(BuildContext context, Category category) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          '/categories/${category.id}',
          extra: category,
        ),
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
                child: const Icon(Icons.category_outlined,
                    color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(category.createdAt),
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    return 'Criada em ${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
