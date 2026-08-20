import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import 'division_form_screen.dart';

/// Gestão de conferências e divisões por campeonato/categoria.
///
/// As divisões aparecem agrupadas sob suas conferências; divisões sem
/// conferência ficam na seção própria ao final da lista.
class GroupingsScreen extends ConsumerWidget {
  const GroupingsScreen({super.key});

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
        title: const Text('Conferências e divisões'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      floatingActionButton: effectiveCat == null
          ? null
          : FloatingActionButton(
              tooltip: 'Nova conferência',
              onPressed: () =>
                  context.push('/conferences/new', extra: effectiveCat),
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
                          onChanged: (value) => ref
                              .read(selectedCategoryProvider.notifier)
                              .state = value,
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
                    : _buildSections(context, ref, effectiveCat),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSections(BuildContext context, WidgetRef ref, String categoryId) {
    final conferences = ref.watch(conferencesProvider(categoryId));
    final divisions = ref.watch(divisionsProvider(categoryId));
    final divItems = divisions.valueOrNull ?? const <Division>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        conferences.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, s) => AppErrorState(
            message: 'Não foi possível carregar as conferências',
            onRetry: () => ref.invalidate(conferencesProvider(categoryId)),
          ),
          data: (confItems) {
            if (confItems.isEmpty) {
              return _sectionCard(
                title: 'Conferências',
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nenhuma conferência cadastrada.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: confItems.map((conf) {
                final confDivisions = divItems
                    .where((d) => d.conferenceId == conf.id)
                    .toList();
                return _conferenceCard(
                  context,
                  ref,
                  categoryId,
                  conf,
                  confDivisions,
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 8),
        divisions.when(
          loading: () => const SizedBox.shrink(),
          error: (e, s) => const SizedBox.shrink(),
          data: (_) {
            final standalone =
                divItems.where((d) => d.conferenceId == null).toList();
            return _sectionCard(
              title: 'Divisões sem conferência',
              action: TextButton.icon(
                onPressed: () => context.push(
                  '/divisions/new',
                  extra: DivisionFormArgs(categoryId: categoryId),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Nova divisão'),
              ),
              child: standalone.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Nenhuma divisão sem conferência.',
                        style:
                            const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : Column(
                      children: standalone
                          .map((d) =>
                              _divisionRow(context, ref, categoryId, d))
                          .toList(),
                    ),
            );
          },
        ),
      ],
    );
  }

  Widget _conferenceCard(
    BuildContext context,
    WidgetRef ref,
    String categoryId,
    Conference conference,
    List<Division> divisions,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.account_tree_outlined,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    conference.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Editar conferência',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push(
                    '/conferences/${conference.id}/edit',
                    extra: conference,
                  ),
                ),
              ],
            ),
            if (divisions.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...divisions.map((d) => _divisionRow(context, ref, categoryId, d)),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.push(
                  '/divisions/new',
                  extra: DivisionFormArgs(
                    categoryId: categoryId,
                    conferenceId: conference.id,
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar divisão'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divisionRow(
    BuildContext context,
    WidgetRef ref,
    String categoryId,
    Division division,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(division.name, style: const TextStyle(fontSize: 14)),
          ),
          IconButton(
            tooltip: 'Editar divisão',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(
              '/divisions/${division.id}/edit',
              extra: division,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    Widget? action,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                ?action,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}