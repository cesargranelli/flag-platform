import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_screen.dart';

/// Elenco de um clube (time) num campeonato (issue #360/#363).
///
/// A tela combina [athletesProvider] (atletas da plataforma) com o
/// [rosterProvider] do time e permite **incluir** atletas ("Incluir") e
/// **removê-los** ("Remover"), sempre invalidando o provider do elenco após a
/// operação. Há busca por nome (TextField) e o action "Importar CSV" é
/// mantido. Atletas já inscritos aparecem com a marcação "No elenco".
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
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  /// Ids de atletas com inclusão em andamento (desabilita a linha).
  final Set<String> _adding = {};

  /// Ids de atletas do elenco com remoção em andamento (desabilita a linha).
  final Set<String> _removing = {};

  String? get _teamId => widget.team?.id ?? widget.teamId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addAthlete(Athlete athlete) async {
    final teamId = _teamId;
    if (teamId == null) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _adding.add(athlete.id));
    try {
      await ref.read(rosterApiProvider).add(
            teamId: teamId,
            athleteId: athlete.id,
          );
      ref.invalidate(rosterProvider(teamId));
      messenger.showSnackBar(
        SnackBar(content: Text('${athlete.name} adicionado ao elenco.')),
      );
    } on RepositoryException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível adicionar o atleta.')),
      );
    } finally {
      if (mounted) setState(() => _adding.remove(athlete.id));
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final teamId = _teamId;
    final teamFuture = widget.team != null
        ? null
        : teamId != null
            ? ref.watch(teamProvider(teamId))
            : null;
    final title =
        widget.team?.name ?? teamFuture?.valueOrNull?.name ?? 'Elenco';

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
      body: teamId == null
          ? const AppEmptyState(
              message: 'Time não identificado',
              icon: Icons.groups_outlined,
            )
          : _buildRoster(context, teamId),
    );
  }

  Widget _buildRoster(BuildContext context, String teamId) {
    final athletesAsync = ref.watch(athletesProvider);
    final rosterAsync = ref.watch(rosterProvider(teamId));

    if (athletesAsync.isLoading || rosterAsync.isLoading) {
      return const AppLoading(message: 'Carregando atletas...');
    }
    if (athletesAsync.hasError) {
      return AppErrorState(
        message: 'Não foi possível carregar os atletas',
        onRetry: () => ref.invalidate(athletesProvider),
      );
    }
    if (rosterAsync.hasError) {
      return AppErrorState(
        message: 'Não foi possível carregar o elenco',
        onRetry: () => ref.invalidate(rosterProvider(teamId)),
      );
    }

    final athletes = athletesAsync.value ?? const <Athlete>[];
    final entries = rosterAsync.value ?? const <RosterEntry>[];
    final inRosterIds = {for (final e in entries) e.athleteId};
    final entryByAthleteId = {for (final e in entries) e.athleteId: e};

    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = athletes
        .where((a) =>
            normalizedQuery.isEmpty ||
            a.name.toLowerCase().contains(normalizedQuery))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppLayout.content(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar atleta',
                hintText: 'Busque pelo nome',
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
          ),
        ),
        Expanded(
          child: _buildList(
            athletes: athletes,
            filtered: filtered,
            inRosterIds: inRosterIds,
            entryByAthleteId: entryByAthleteId,
          ),
        ),
      ],
    );
  }

  Widget _buildList({
    required List<Athlete> athletes,
    required List<Athlete> filtered,
    required Set<String> inRosterIds,
    required Map<String, RosterEntry> entryByAthleteId,
  }) {
    if (athletes.isEmpty) {
      return const AppEmptyState(
        message: 'Nenhum atleta encontrado',
        icon: Icons.person_outline,
      );
    }
    if (filtered.isEmpty) {
      return const AppEmptyState(
        message: 'Nenhum atleta encontrado',
        icon: Icons.search_off,
      );
    }

    final allInRoster = athletes.every((a) => inRosterIds.contains(a.id));
    final showAllInRosterNote = allInRoster && _query.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showAllInRosterNote)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Todos os atletas já estão no elenco',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        Expanded(
          child: AppLayout.content(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final athlete = filtered[index];
                final inRoster = inRosterIds.contains(athlete.id);
                return _athleteCard(
                  context,
                  athlete,
                  inRoster: inRoster,
                  entry: inRoster ? entryByAthleteId[athlete.id] : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _athleteCard(
    BuildContext context,
    Athlete athlete, {
    required bool inRoster,
    required RosterEntry? entry,
  }) {
    final position = athlete.position?.label ?? '';
    final subtitle = [
      if (athlete.number != null) '#${athlete.number}',
      if (position.isNotEmpty) position,
    ].join(' · ');
    final adding = _adding.contains(athlete.id);
    final removing = _removing.contains(athlete.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Row(
          children: [
            _athleteAvatar(athlete, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    athlete.name,
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
            const SizedBox(width: 8),
            if (adding || removing)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (inRoster)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _InRosterBadge(),
                  IconButton(
                    tooltip: 'Remover atleta',
                    icon: const Icon(Icons.person_remove_outlined),
                    onPressed: entry == null ? null : () => _removeAthlete(entry),
                  ),
                ],
              )
            else
              FilledButton.tonal(
                onPressed: () => _addAthlete(athlete),
                child: const Text('Incluir'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _athleteAvatar(Athlete athlete, {required double size}) {
    final photo = athlete.photoUrl;
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
                  _initials(athlete.name),
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
                _initials(athlete.name),
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

/// Marcação visual de atleta já inscrito no elenco (não permite re-incluir).
class _InRosterBadge extends StatelessWidget {
  const _InRosterBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 20),
        const SizedBox(width: 6),
        Text(
          'No elenco',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}
