import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Gestão de times: lista por campeonato/categoria e acesso ao detalhe.
///
/// A cascata campeonato → categoria define o contexto da listagem; clicar em
/// um time navega para o detalhe.
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
      appBar: AppBar(
        title: const Text('Times'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
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
                        data: (items) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
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
                                '${ref.watch(teamsProvider(effectiveCat)).valueOrNull?.length ?? 0} '
                                '${ref.watch(teamsProvider(effectiveCat)).valueOrNull?.length == 1 ? 'time' : 'times'}',
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
                    : ref.watch(teamsProvider(effectiveCat)).when(
                        loading: () => const AppLoading(message: 'Carregando times...'),
                        error: (error, stackTrace) => AppErrorState(
                          message: 'Não foi possível carregar os times',
                          onRetry: () =>
                              ref.invalidate(teamsProvider(effectiveCat)),
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
                                    final team = items[index];
                                    return _teamCard(context, team);
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

  Widget _teamCard(BuildContext context, Team team) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/teams/${team.id}', extra: team),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _teamAvatar(team, size: 48, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    if (team.shortName != null && team.shortName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        team.shortName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamAvatar(Team team,
      {required double size, required double radius}) {
    final logo = team.logoUrl;
    final validLogo = logo != null &&
        logo.isNotEmpty &&
        (Uri.tryParse(logo)?.hasScheme ?? false);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: validLogo
          ? Image.network(
              logo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.groups_outlined,
                      color: AppColors.primary, size: 28),
            )
          : const Icon(Icons.groups_outlined,
              color: AppColors.primary, size: 28),
    );
  }
}
