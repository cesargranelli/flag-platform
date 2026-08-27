import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_screen.dart';

/// Elenco de um clube (time) num campeonato (issue #360).
///
/// O elenco é a associação de atletas ao clube naquele campeonato. A tela
/// lista os atletas do [rosterProvider] do time e permite adicionar (buscar
/// atleta em [athletesProvider] e chamar `RosterApi.add`) e remover
/// (`RosterApi.remove`) — sempre invalidando o provider do elenco após a
/// operação.
class TeamRosterScreen extends ConsumerStatefulWidget {
  const TeamRosterScreen({super.key, this.team, this.teamId});

  /// Time (clube + competição) quando navegamos com `state.extra`.
  final Team? team;

  /// Id do time, derivado da rota `/teams/:id/roster`.
  final String? teamId;

  @override
  ConsumerState<TeamRosterScreen> createState() => _TeamRosterScreenState();
}

class _TeamRosterScreenState extends ConsumerState<TeamRosterScreen> {
  /// Ids de atletas do elenco com remoção em andamento (desabilita a linha).
  final Set<String> _removing = {};

  String? get _teamId => widget.team?.id ?? widget.teamId;

  Future<void> _removeAthlete(RosterEntry entry) async {
    final teamId = _teamId;
    if (teamId == null) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _removing.add(entry.athleteId));
    try {
      await ref.read(rosterApiProvider).remove(
            teamId: teamId,
            athleteId: entry.athleteId,
          );
      ref.invalidate(rosterProvider(teamId));
      messenger.showSnackBar(
        SnackBar(content: Text('${entry.athleteName} removido do elenco.')),
      );
    } on RepositoryException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível remover o atleta.')),
      );
    } finally {
      if (mounted) setState(() => _removing.remove(entry.athleteId));
    }
  }

  Future<void> _openAddAthleteDialog() async {
    final teamId = _teamId;
    if (teamId == null) return;

    final entries = ref.read(rosterProvider(teamId)).valueOrNull ?? const [];
    final existing = {for (final e in entries) e.athleteId};

    await showDialog<void>(
      context: context,
      builder: (_) => _RosterAddAthleteDialog(
        teamId: teamId,
        existingAthleteIds: existing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamId = _teamId;
    final teamFuture = widget.team != null
        ? null
        : teamId != null
            ? ref.watch(teamProvider(teamId))
            : null;
    final title = widget.team?.name ??
        teamFuture?.valueOrNull?.name ??
        'Elenco';

    return AppScreen(
      title: title,
      leading: AppBackButton(fallbackRoute: '/rosters'),
      actions: [
        if (teamId != null)
          IconButton(
            tooltip: 'Importar CSV',
            icon: const Icon(Icons.upload_file),
            onPressed: () => context.push('/rosters/import', extra: teamId),
          ),
      ],
      floatingActionButton: teamId == null
          ? null
          : FloatingActionButton(
              tooltip: 'Adicionar atleta',
              onPressed: _openAddAthleteDialog,
              child: const Icon(Icons.person_add_alt_1),
            ),
      body: teamId == null
          ? const AppEmptyState(
              message: 'Time não identificado',
              icon: Icons.groups_outlined,
            )
          : ref.watch(rosterProvider(teamId)).when(
              loading: () => const AppLoading(message: 'Carregando elenco...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar o elenco',
                onRetry: () => ref.invalidate(rosterProvider(teamId)),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return const AppEmptyState(
                    message: 'Nenhum atleta no elenco',
                    icon: Icons.person_outline,
                  );
                }
                return AppLayout.content(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _entryCard(context, entries[index]),
                  ),
                );
              },
            ),
    );
  }

  Widget _entryCard(BuildContext context, RosterEntry entry) {
    final position = entry.position?.label ?? '';
    final subtitle = [
      if (entry.number != null) '#${entry.number}',
      if (position.isNotEmpty) position,
      if (entry.athleteNickname != null && entry.athleteNickname!.isNotEmpty)
        entry.athleteNickname!,
    ].join(' · ');
    final removing = _removing.contains(entry.athleteId);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Row(
          children: [
            _avatar(entry, size: 48),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (removing)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: 'Remover atleta',
                icon: const Icon(Icons.person_remove_outlined),
                onPressed: () => _removeAthlete(entry),
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(RosterEntry entry, {required double size}) {
    final photo = entry.photoUrl;
    final validPhoto = photo != null &&
        photo.isNotEmpty &&
        (Uri.tryParse(photo)?.hasScheme ?? false);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: validPhoto
          ? Image.network(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  _initials(entry.athleteName),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: size * 0.4,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                _initials(entry.athleteName),
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.4,
                ),
              ),
            ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

/// Diálogo de seleção de atleta para adicionar ao elenco (issue #360).
///
/// Busca atletas de [athletesProvider] por nome, oculta os que já constam no
/// elenco do time e permite adicionar com um toque. O diálogo fecha após o
/// sucesso e a lista é invalidada pelo provider de elenco.
class _RosterAddAthleteDialog extends ConsumerStatefulWidget {
  const _RosterAddAthleteDialog({
    required this.teamId,
    required this.existingAthleteIds,
  });

  final String teamId;
  final Set<String> existingAthleteIds;

  @override
  ConsumerState<_RosterAddAthleteDialog> createState() =>
      _RosterAddAthleteDialogState();
}

class _RosterAddAthleteDialogState
    extends ConsumerState<_RosterAddAthleteDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  /// Ids de atletas com adição em andamento (evita toque duplo).
  final Set<String> _adding = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _add(Athlete athlete) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _adding.add(athlete.id));
    try {
      await ref.read(rosterApiProvider).add(
            teamId: widget.teamId,
            athleteId: athlete.id,
          );
      ref.invalidate(rosterProvider(widget.teamId));
      if (mounted) Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text('${athlete.name} adicionado ao elenco.')),
      );
    } on RepositoryException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      if (mounted) setState(() => _adding.remove(athlete.id));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível adicionar o atleta.')),
      );
      if (mounted) setState(() => _adding.remove(athlete.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final athletesAsync = ref.watch(athletesProvider);

    return AlertDialog(
      title: const Text('Adicionar atleta'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppLayout.maxFormWidth,
          maxHeight: 520,
        ),
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Busque por nome e toque em um atleta para adicioná-lo ao '
                'elenco (atletas já inscritos são ocultados).',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar atleta',
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
              const SizedBox(height: 8),
              Expanded(
                child: athletesAsync.when(
                  loading: () =>
                      const AppLoading(message: 'Carregando atletas...'),
                  error: (error, stackTrace) => AppErrorState(
                    message: 'Não foi possível carregar os atletas',
                    onRetry: () => ref.invalidate(athletesProvider),
                  ),
                  data: (athletes) {
                    final normalizedQuery = _query.trim().toLowerCase();
                    final filtered = athletes
                        .where((a) => !widget.existingAthleteIds.contains(a.id))
                        .where((a) =>
                            normalizedQuery.isEmpty ||
                            a.name.toLowerCase().contains(normalizedQuery))
                        .toList();

                    if (athletes.isEmpty) {
                      return const AppEmptyState(
                        message: 'Nenhum atleta cadastrado',
                        icon: Icons.person_outline,
                      );
                    }
                    if (filtered.isEmpty) {
                      return normalizedQuery.isEmpty
                          ? const AppEmptyState(
                              message: 'Todos os atletas já estão no elenco',
                              icon: Icons.check_circle_outline,
                            )
                          : AppEmptyState(
                              message:
                                  'Nenhum atleta encontrado para "$_query".',
                              icon: Icons.search_off,
                            );
                    }
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          _athleteTile(filtered[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _athleteTile(Athlete athlete) {
    final adding = _adding.contains(athlete.id);
    final position = athlete.position?.label ?? '';
    final subtitle = [
      if (athlete.number != null) '#${athlete.number}',
      if (position.isNotEmpty) position,
    ].join(' · ');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: Text(
          _initials(athlete.name),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      title: Text(athlete.name),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: adding
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_circle_outline),
      onTap: adding ? null : () => _add(athlete),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
