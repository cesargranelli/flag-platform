import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Modal de associação de clubes a uma divisão (issue #258).
///
/// Lista os times do campeonato com busca textual; tocar em um clube alterna
/// sua divisão para a divisão-alvo do modal (ou remove, caso já pertença a
/// ela). Clubes podem ficar sem divisão — comportamento permitido pelo
/// backend. Substitui o fluxo manual de editar cada time individualmente.
Future<void> showClubAssignmentModal(
  BuildContext context, {
  required String competitionId,
  required Division division,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ClubAssignmentModal(
      competitionId: competitionId,
      division: division,
    ),
  );
}

class ClubAssignmentModal extends ConsumerStatefulWidget {
  const ClubAssignmentModal({
    super.key,
    required this.competitionId,
    required this.division,
  });

  final String competitionId;
  final Division division;

  @override
  ConsumerState<ClubAssignmentModal> createState() =>
      _ClubAssignmentModalState();
}

class _ClubAssignmentModalState extends ConsumerState<ClubAssignmentModal> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  /// Times com salvamento em andamento (desabilita a linha durante o PUT).
  final Set<String> _savingTeamIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Associa ou remove o clube da divisão-alvo, enviando o corpo completo
  /// exigido pelo backend (inclui `organizationId`).
  Future<void> _toggleDivision(Team team) async {
    final removing = team.divisionId == widget.division.id;
    final organizationId = team.organizationId;
    if (organizationId == null || organizationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${team.name} está sem organização vinculada.'),
        ),
      );
      return;
    }

    // Capturados antes do await: o diálogo pode fechar/mudar de contexto.
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _savingTeamIds.add(team.id));
    try {
      await ref.read(teamApiProvider).update(
            team.id,
            organizationId: organizationId,
            competitionId: team.competitionId,
            divisionId: removing ? null : widget.division.id,
            name: team.name,
            shortName: team.shortName,
            document: team.document,
            documentType: team.documentType,
            logoUrl: team.logoUrl,
          );
      ref.invalidate(teamsProvider(widget.competitionId));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            removing
                ? '${team.name} removido da divisão ${widget.division.name}.'
                : '${team.name} adicionado à divisão ${widget.division.name}.',
          ),
        ),
      );
    } on RepositoryException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível atualizar o clube.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingTeamIds.remove(team.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsProvider(widget.competitionId));
    final divisionsAsync = ref.watch(divisionsProvider(widget.competitionId));

    return AlertDialog(
      title: Text('Associar clubes · ${widget.division.name}'),
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
                'Toque em um clube para associá-lo a esta divisão ou removê-la '
                '(clube pode ficar sem divisão).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar clube',
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
                child: teamsAsync.when(
                  loading: () =>
                      const AppLoading(message: 'Carregando clubes...'),
                  error: (error, stackTrace) => AppErrorState(
                    message: 'Não foi possível carregar os clubes',
                    onRetry: () =>
                        ref.invalidate(teamsProvider(widget.competitionId)),
                  ),
                  data: (teams) {
                    final divisionsByName = <String, String>{
                      for (final d
                          in divisionsAsync.valueOrNull ?? const <Division>[])
                        d.id: d.name,
                    };
                    final normalizedQuery = _query.trim().toLowerCase();
                    final filtered = normalizedQuery.isEmpty
                        ? teams
                        : teams
                            .where((t) =>
                                t.name.toLowerCase().contains(normalizedQuery))
                            .toList();

                    if (teams.isEmpty) {
                      return const AppEmptyState(
                        message: 'Nenhum clube inscrito neste campeonato.',
                        icon: Icons.groups_outlined,
                      );
                    }
                    if (filtered.isEmpty) {
                      return AppEmptyState(
                        message: 'Nenhum clube encontrado para "$_query".',
                        icon: Icons.search_off,
                      );
                    }
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _teamTile(
                        filtered[index],
                        divisionsByName,
                      ),
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
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  /// Linha de um clube: nome + divisão atual; tocar alterna a associação.
  Widget _teamTile(Team team, Map<String, String> divisionsById) {
    final inTargetDivision = team.divisionId == widget.division.id;
    final saving = _savingTeamIds.contains(team.id);
    final currentDivision =
        team.divisionId == null ? null : divisionsById[team.divisionId];

    return ListTile(
      leading: const Icon(Icons.groups_outlined),
      title: Text(team.name),
      subtitle: Text(
        inTargetDivision
            ? 'Nesta divisão'
            : currentDivision != null && currentDivision.isNotEmpty
                ? 'Divisão atual: $currentDivision'
                : 'Sem divisão',
      ),
      tileColor:
          inTargetDivision ? AppColors.primary.withValues(alpha: 0.08) : null,
      trailing: saving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : inTargetDivision
              ? const Icon(Icons.check_circle, color: AppColors.success)
              : const Icon(Icons.add_circle_outline),
      onTap: saving ? null : () => _toggleDivision(team),
    );
  }
}
