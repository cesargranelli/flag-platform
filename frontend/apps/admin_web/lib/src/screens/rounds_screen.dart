import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Gestão de rodadas: lista por campeonato/categoria e acesso ao detalhe.
///
/// A cascata campeonato → categoria define o contexto da listagem; clicar em
/// uma rodada navega para o detalhe.
class RoundsScreen extends ConsumerWidget {
  const RoundsScreen({super.key});

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
      appBar: AppBar(
        title: const Text('Rodadas'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      floatingActionButton: effectiveCat == null
          ? null
          : FloatingActionButton(
              tooltip: 'Nova rodada',
              onPressed: () => context.push('/rounds/new', extra: effectiveCat),
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
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ))
                            .toList(),
                        onChanged: (value) {
                          ref
                              .read(selectedCompetitionProvider.notifier)
                              .state = value;
                          ref.read(selectedCategoryProvider.notifier).state = null;
                        },
                      ),
                      const SizedBox(height: 12),
                      categories!.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, s) => AppErrorState(
                          message: 'Não foi possível carregar as categorias',
                          onRetry: () =>
                              ref.invalidate(categoriesProvider(effectiveComp!)),
                        ),
                        data: (items) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              key: ValueKey('cat-$effectiveCat'),
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
                              onChanged: (value) => ref
                                  .read(selectedCategoryProvider.notifier)
                                  .state = value,
                            ),
                            const SizedBox(height: 12),
                            if (effectiveCat != null)
                              Text(
                                '${ref.watch(roundsProvider(effectiveCat)).valueOrNull?.length ?? 0} '
                                '${ref.watch(roundsProvider(effectiveCat)).valueOrNull?.length == 1 ? 'rodada' : 'rodadas'}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: effectiveCat == null
                    ? const AppEmptyState(
                        message: 'Nenhuma categoria cadastrada',
                        icon: Icons.category_outlined,
                      )
                    : ref.watch(roundsProvider(effectiveCat)).when(
                        loading: () => const AppLoading(message: 'Carregando rodadas...'),
                        error: (error, stackTrace) => AppErrorState(
                          message: 'Não foi possível carregar as rodadas',
                          onRetry: () =>
                              ref.invalidate(roundsProvider(effectiveCat)),
                        ),
                        data: (items) {
                          if (items.isEmpty) {
                            return const AppEmptyState(
                              message: 'Nenhuma rodada cadastrada',
                              icon: Icons.format_list_numbered,
                            );
                          }
                          return AppLayout.content(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final columns =
                                    constraints.maxWidth >= 600 ? 2 : 1;
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
                                    final round = items[index];
                                    return _roundCard(context, round);
                                  },
                                );
                              },
                            ),
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

  Widget _roundCard(BuildContext context, Round round) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/rounds/${round.id}', extra: round),
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
                    '${round.number}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
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
                      round.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      round.type.label,
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
}
