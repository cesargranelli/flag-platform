import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Argumentos de navegação da página do time (rota `/teams/:id`).
///
/// O nome é passado via `extra` no `context.push` para exibição imediata;
/// em deep links (sem `extra`) a tela busca os dados por id.
class TeamDetailArgs {
  final String teamId;
  final String teamName;

  const TeamDetailArgs({required this.teamId, this.teamName = ''});
}

/// Abre a página pública do time quando houver id; caso contrário, ignora.
///
/// Usada pelos cards de jogo (calendário/resultados/detalhe) e pela tabela
/// de classificação ao tocar no nome de um time.
void openTeamDetail(BuildContext context, {String? teamId, String? teamName}) {
  final id = teamId?.trim();
  if (id == null || id.isEmpty) return;
  context.push(
    '/teams/$id',
    extra: TeamDetailArgs(teamId: id, teamName: teamName ?? ''),
  );
}

/// Tela pública de um time: dados do time e elenco (roster) de atletas.
class TeamDetailScreen extends ConsumerWidget {
  final String teamId;
  final String teamName;

  const TeamDetailScreen({super.key, required this.teamId, this.teamName = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final title = teamName.isEmpty ? 'Time' : teamName;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: teamAsync.when(
        loading: () => const AppLoading(message: 'Carregando time...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar o time',
          onRetry: () => ref.invalidate(teamDetailProvider(teamId)),
        ),
        data: (team) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TeamHeader(team: team),
            const SizedBox(height: 24),
            _RosterSection(teamId: teamId),
          ],
        ),
      ),
    );
  }
}

/// Cabeçalho do time: escudo (quando houver logo), nome e apelido.
class _TeamHeader extends StatelessWidget {
  final Team team;

  const _TeamHeader({required this.team});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _TeamLogo(logoUrl: team.logoUrl),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (team.shortName != null && team.shortName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      team.shortName!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Escudo do time com fallback para ícone quando não há logo válida.
class _TeamLogo extends StatelessWidget {
  final String? logoUrl;

  const _TeamLogo({this.logoUrl});

  @override
  Widget build(BuildContext context) {
    final logo = logoUrl;
    final validLogo =
        logo != null &&
        logo.isNotEmpty &&
        (Uri.tryParse(logo)?.hasScheme ?? false);

    return Container(
      width: 72,
      height: 72,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: validLogo
          ? Image.network(
              logo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.groups_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            )
          : const Icon(
              Icons.groups_outlined,
              size: 36,
              color: AppColors.primary,
            ),
    );
  }
}

/// Seção do elenco: agrupa os atletas por posição (ordem QB → P do domínio)
/// e, dentro de cada grupo, ordena por número (sem número ao final) e nome.
class _RosterSection extends ConsumerWidget {
  final String teamId;

  const _RosterSection({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(teamRosterProvider(teamId));

    return rosterAsync.when(
      loading: () => const AppLoading(message: 'Carregando elenco...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Não foi possível carregar o elenco',
        onRetry: () => ref.invalidate(teamRosterProvider(teamId)),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const AppEmptyState(
            message: 'Nenhum atleta inscrito neste time',
            icon: Icons.groups_outlined,
          );
        }

        final sorted = _sortedEntries(entries);
        final groups = <String, List<RosterEntry>>{
          for (final position in AthletePosition.values)
            position.label: sorted
                .where((entry) => entry.position == position)
                .toList(),
          'Sem posição': sorted
              .where((entry) => entry.position == null)
              .toList(),
        }..removeWhere((_, list) => list.isEmpty);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.groups_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Elenco (${entries.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final entry in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < entry.value.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 68),
                      _AthleteTile(entry: entry.value[i]),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Ordenação estável: número crescente (nulos ao final) e depois nome.
  List<RosterEntry> _sortedEntries(List<RosterEntry> entries) {
    final sorted = [...entries]
      ..sort((a, b) {
        final numberA = a.number;
        final numberB = b.number;
        if (numberA == null && numberB != null) return 1;
        if (numberA != null && numberB == null) return -1;
        final byNumber = (numberA ?? 0).compareTo(numberB ?? 0);
        if (byNumber != 0) return byNumber;
        return a.athleteName.toLowerCase().compareTo(
          b.athleteName.toLowerCase(),
        );
      });
    return sorted;
  }
}

/// Linha de um atleta: foto/iniciais, número, nome/apelido e posição.
class _AthleteTile extends StatelessWidget {
  final RosterEntry entry;

  const _AthleteTile({required this.entry});

  bool get _inactive => entry.status.toUpperCase() == 'INACTIVE';

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (entry.athleteNickname != null && entry.athleteNickname!.isNotEmpty)
        '"${entry.athleteNickname}"',
      if (entry.position != null) entry.position!.label,
      if (_inactive) 'Inativo',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _AthleteAvatar(photoUrl: entry.photoUrl, name: entry.athleteName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.athleteName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _inactive
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    details.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: _inactive
                          ? AppColors.disabled
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.grayFill,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              entry.number?.toString() ?? '-',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Foto do atleta com fallback para as iniciais do nome.
class _AthleteAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;

  const _AthleteAvatar({this.photoUrl, required this.name});

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final photo = photoUrl;
    final validPhoto =
        photo != null &&
        photo.isNotEmpty &&
        (Uri.tryParse(photo)?.hasScheme ?? false);

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      backgroundImage: validPhoto ? NetworkImage(photo) : null,
      child: validPhoto
          ? null
          : Text(
              _initials,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
    );
  }
}
