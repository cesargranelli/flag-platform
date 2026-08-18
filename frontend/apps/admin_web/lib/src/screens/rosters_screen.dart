import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
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
        actions: [
          if (effectiveTeam != null)
            IconButton(
              tooltip: 'Importar CSV',
              icon: const Icon(Icons.upload_file),
              onPressed: () => context.push('/rosters/import', extra: effectiveTeam),
            ),
        ],
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
                            .map((c) =>
                                DropdownMenuItem(value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (value) {
                          ref
                              .read(selectedCompetitionProvider.notifier)
                              .state = value;
                          ref.read(selectedCategoryProvider.notifier).state = null;
                          ref.read(selectedTeamProvider.notifier).state = null;
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
                          key: ValueKey('cat-$effectiveCat'),
                          initialValue: effectiveCat,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            border: OutlineInputBorder(),
                          ),
                          items: items
                              .map((c) =>
                                  DropdownMenuItem(value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (value) {
                            ref
                                .read(selectedCategoryProvider.notifier)
                                .state = value;
                            ref.read(selectedTeamProvider.notifier).state = null;
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      (teams?.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, s) => AppErrorState(
                          message: 'Não foi possível carregar os times',
                          onRetry: () =>
                              ref.invalidate(teamsProvider(effectiveCat!)),
                        ),
                        data: (items) => DropdownButtonFormField<String>(
                          key: ValueKey('team-$effectiveTeam'),
                          initialValue: effectiveTeam,
                          decoration: const InputDecoration(
                            labelText: 'Time',
                            border: OutlineInputBorder(),
                          ),
                          items: items
                              .map((t) =>
                                  DropdownMenuItem(value: t.id, child: Text(t.name)))
                              .toList(),
                          onChanged: (value) =>
                              ref.read(selectedTeamProvider.notifier).state = value,
                        ),
                      ) ??
                      const LinearProgressIndicator()),
                    ],
                  ),
                ),
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
                                    final entry = items[index];
                                    return _entryCard(
                                      context,
                                      ref,
                                      entry,
                                      teamId: effectiveTeam,
                                    );
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

  Widget _entryCard(
    BuildContext context,
    WidgetRef ref,
    RosterEntry entry, {
    required String teamId,
  }) {
    final position = entry.position?.label ?? '';
    final subtitle = [
      if (entry.number != null) 'Camisa ${entry.number}',
      if (position.isNotEmpty) position,
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
        child: Row(
          children: [
            _avatar(entry),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.athleteName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remover do elenco',
              icon: const Icon(Icons.remove_circle_outline,
                  color: AppColors.danger),
              onPressed: () => _confirmRemove(context, ref, entry, teamId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(RosterEntry entry) {
    final photo = entry.photoUrl;
    final validPhoto = photo != null &&
        photo.isNotEmpty &&
        (Uri.tryParse(photo)?.hasScheme ?? false);
    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: validPhoto
          ? Image.network(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(Icons.person,
                  color: AppColors.primary),
            )
          : const Icon(Icons.person, color: AppColors.primary),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    RosterEntry entry,
    String teamId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover do elenco'),
        content: Text('Remover ${entry.athleteName} do elenco?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(rosterApiProvider)
          .remove(teamId: teamId, athleteId: entry.athleteId);
      ref.invalidate(rosterProvider(teamId));
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('${entry.athleteName} removido do elenco')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível remover o atleta')),
        );
      }
    }
  }

  Future<void> _showAddDialog(
      BuildContext context, WidgetRef ref, String teamId) async {
    // Carrega atletas e já inscritos antes de abrir o dialog (estados tratados).
    final List<Athlete>? athletes;
    try {
      athletes = await ref.read(athletesProvider.future);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível carregar os atletas')),
        );
      }
      return;
    }
    if (!context.mounted) return;

    final enrolledIds = ref
            .read(rosterProvider(teamId))
            .valueOrNull
            ?.map((e) => e.athleteId)
            .toSet() ??
        {};
    final available = (athletes ?? const <Athlete>[])
        .where((a) => !enrolledIds.contains(a.id))
        .toList();

    String? athleteId;
    final added = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Inscrever atleta'),
          content: SizedBox(
            width: 400,
            child: available.isEmpty
                ? const AppEmptyState(
                    message: 'Todos os atletas já estão inscritos',
                    icon: Icons.groups_outlined,
                  )
                : DropdownButtonFormField<String>(
                    initialValue: athleteId,
                    decoration: const InputDecoration(
                      labelText: 'Atleta',
                      border: OutlineInputBorder(),
                    ),
                    items: available
                        .map((a) =>
                            DropdownMenuItem(value: a.id, child: Text(a.name)))
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => athleteId = value),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: athleteId == null
                  ? null
                  : () => Navigator.pop(dialogContext, athleteId),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );

    if (added is String && added.isNotEmpty) {
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(rosterApiProvider).add(teamId: teamId, athleteId: added);
        ref.invalidate(rosterProvider(teamId));
        if (context.mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Atleta inscrito no elenco')),
          );
        }
      } catch (_) {
        if (context.mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Não foi possível inscrever o atleta')),
          );
        }
      }
    }
  }
}
