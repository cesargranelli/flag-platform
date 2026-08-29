import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../widgets/app_screen.dart';
import '../widgets/edit_restriction_note.dart';

/// Gestão de times: lista por campeonato e acesso ao detalhe.
///
/// O fluxo agora é: campeonato → times.
/// Os times associam-se diretamente ao competition_id (migração V24);
/// as categories foram removidas.
class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key, this.lockedCompetitionId});

  /// Quando informado, a tela fica "travada" nesse campeonato (dropdown
  /// desabilitado) — usado ao vir do detalhe do campeonato (#349).
  final String? lockedCompetitionId;

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);
    final selectedCompetition = ref.watch(selectedCompetitionProvider);

    final lockedCompetitionId = widget.lockedCompetitionId;
    final compItems = competitions.valueOrNull ?? const [];
    final effectiveComp =
        lockedCompetitionId ??
        selectedCompetition ??
        (compItems.isNotEmpty ? compItems.first.id : null);
    final locked = lockedCompetitionId != null;

    // Issue #261: inscrição de times exige ser criador do campeonato
    // ou ADMIN (o backend já bloqueia as escritas).
    final selectedCompetitionObj = compItems
        .where((c) => c.id == effectiveComp)
        .firstOrNull;
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider).state.user,
      selectedCompetitionObj,
    );

    return AppScreen(
      title: 'Times',
      actions: [
        if (effectiveComp != null && canEdit)
          KicksterButton(
            label: 'Novo',
            icon: Icons.add,
            onPressed: () => context.go('/teams/new', extra: effectiveComp),
          ),
      ],
      body: competitions.when(
        loading: () => const AppLoading(message: 'Carregando campeonatos...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar os campeonatos',
          onRetry: () => ref.invalidate(competitionsProvider),
        ),
        data: (_) {
          if (compItems.isEmpty) {
            return KicksterEmptyState(
              icon: Icons.emoji_events_outlined,
              message: 'Nenhum campeonato cadastrado',
              description: 'Crie um campeonato para inscrever times.',
              action: KicksterButton(
                label: 'Criar campeonato',
                icon: Icons.add,
                onPressed: () => context.go('/competitions/new'),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KicksterDropdown<String>(
                    label: locked ? 'Campeonato (travado)' : 'Campeonato',
                    value: effectiveComp,
                    items: compItems
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: appDropdownItem(
                              Icons.emoji_events_outlined,
                              c.name,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: locked
                        ? null
                        : (value) {
                            ref
                                .read(selectedCompetitionProvider.notifier)
                                .state = value;
                          },
                  ),
                  if (!canEdit)
                    const EditRestrictionNote(
                      message:
                          'Apenas o criador do campeonato pode '
                          'inscrever times.',
                    ),
                ],
              ),
              if (effectiveComp != null)
                ref
                      .watch(teamsProvider(effectiveComp))
                      .when(
                        loading: () => const AppLoading(
                          message: 'Carregando times...',
                        ),
                        error: (error, stackTrace) => AppErrorState(
                          message: 'Não foi possível carregar os times',
                          onRetry: () =>
                              ref.invalidate(teamsProvider(effectiveComp)),
                        ),
                        data: (items) {
                          if (items.isEmpty) {
                            return KicksterEmptyState(
                              icon: Icons.groups_outlined,
                              message: 'Nenhum time cadastrado',
                              description:
                                  'Inscreva o primeiro time no campeonato.',
                              action: KicksterButton(
                                label: 'Criar time',
                                icon: Icons.add,
                                onPressed: () => context.go(
                                  '/teams/new',
                                  extra: effectiveComp,
                                ),
                              ),
                            );
                          }
                          final query = _query.trim().toLowerCase();
                          final filtered = query.isEmpty
                              ? items
                              : items
                                  .where(
                                    (t) =>
                                        t.name.toLowerCase().contains(query),
                                  )
                                  .toList(growable: false);

                          return Column(
                            children: [
                              Row(
                                children: [
                                  if (query.isNotEmpty)
                                    Text(
                                      '${filtered.length} '
                                      '${filtered.length == 1 ? 'resultado' : 'resultados'}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color:
                                            AppColors.textSecondary,
                                      ),
                                    )
                                  else
                                    Text(
                                      '${items.length} '
                                      '${items.length == 1 ? 'time' : 'times'}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color:
                                            AppColors.textSecondary,
                                      ),
                                    ),
                                  const Spacer(),
                                  SizedBox(
                                    width: 280,
                                    child: KicksterSearchField(
                                      controller: _searchController,
                                      onChanged: (value) => setState(
                                          () => _query = value),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (filtered.isEmpty)
                                const AppEmptyState(
                                  message:
                                      'Nenhum time encontrado',
                                  icon: Icons.search_off,
                                )
                              else
                                LayoutBuilder(
                                  builder:
                                      (context, constraints) {
                                    final columns =
                                        constraints.maxWidth >= 600
                                            ? 2
                                            : 1;
                                    return GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding:
                                          const EdgeInsets.all(16),
                                      itemCount: filtered.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount:
                                                columns,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            mainAxisExtent: 96,
                                          ),
                                      itemBuilder:
                                          (context, index) {
                                            final team =
                                                filtered[index];
                                            return _teamCard(
                                                context, team);
                                          },
                                    );
                                  },
                                ),
                            ],
                          );
                        },
                      )
              else
                const AppEmptyState(
                    message: 'Nenhum time cadastrado',
                    icon: Icons.groups_outlined,
                  ),
            ],
          );
        },
      ),
    );
  }

  /// Card de time no padrão Kickster (core #439): ícone de grupo, nome e
  /// subtítulo com esporte + contagem de atletas.
  Widget _teamCard(BuildContext context, Team team) {
    final subtitle = [
      if (team.sportName?.isNotEmpty ?? false) team.sportName!,
      '${team.athleteCount ?? 0} atletas',
    ].join(' · ');

    return KicksterCard(
      icon: Icons.groups_outlined,
      title: team.name,
      subtitle: subtitle,
      onTap: () => context.push('/teams/${team.id}', extra: team),
    );
  }
}
