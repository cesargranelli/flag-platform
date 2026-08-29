import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../widgets/app_screen.dart';
import '../widgets/edit_restriction_note.dart';

/// Gestão de rodadas: lista por campeonato e acesso ao detalhe.
///
/// O fluxo agora é: campeonato → rodadas.
/// As categories foram removidas; as rodadas associam-se diretamente
/// ao competition_id (migração V24).
class RoundsScreen extends ConsumerStatefulWidget {
  const RoundsScreen({super.key});

  @override
  ConsumerState<RoundsScreen> createState() => _RoundsScreenState();
}

class _RoundsScreenState extends ConsumerState<RoundsScreen> {
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

    final compItems = competitions.valueOrNull ?? const [];
    final effectiveComp =
        selectedCompetition ??
        (compItems.isNotEmpty ? compItems.first.id : null);

    // Issue #261: criação/edição de rodadas exige ser criador do
    // campeonato ou ADMIN (o backend já bloqueia as escritas).
    // Issue #305: e apenas com o campeonato em DRAFT — publicado/encerrado
    // tem a estrutura travada (somente leitura).
    final selectedCompetitionObj = compItems
        .where((c) => c.id == effectiveComp)
        .firstOrNull;
    final isDraft =
        selectedCompetitionObj?.status == CompetitionStatus.draft;
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider).state.user,
      selectedCompetitionObj,
    );
    final canManage = canEdit && isDraft;

    return AppScreen(
      title: 'Rodadas',
      titleVariant: AppScreenTitleVariant.titleLg,
      actions: [
        if (effectiveComp != null && canManage)
          KicksterButton(
            label: 'Novo',
            icon: Icons.add,
            onPressed: () => context.go('/rounds/new', extra: effectiveComp),
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
              description: 'Crie um campeonato para adicionar rodadas.',
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
              AppLayout.content(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KicksterDropdown<String>(
                        key: ValueKey('comp-$effectiveComp'),
                        label: 'Campeonato',
                        value: effectiveComp,
                        items: compItems
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          ref.read(selectedCompetitionProvider.notifier).state =
                              value;
                          ref.read(selectedRoundProvider.notifier).state = null;
                        },
                      ),
                      if (!canManage)
                        EditRestrictionNote(
                          message: !isDraft
                              ? 'Campeonato publicado — as rodadas estão '
                                  'travadas.'
                              : 'Apenas o criador do campeonato pode '
                                  'gerenciar rodadas.',
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: effectiveComp != null
                    ? ref
                          .watch(roundsProvider(effectiveComp))
                          .when(
                            loading: () => const AppLoading(
                              message: 'Carregando rodadas...',
                            ),
                            error: (error, stackTrace) => AppErrorState(
                              message: 'Não foi possível carregar as rodadas',
                              onRetry: () =>
                                  ref.invalidate(roundsProvider(effectiveComp)),
                            ),
                            data: (items) {
                              if (items.isEmpty) {
                                return KicksterEmptyState(
                                  icon: Icons.format_list_numbered,
                                  message: 'Nenhuma rodada cadastrada',
                                  description:
                                      'Crie a primeira rodada do campeonato.',
                                  action: KicksterButton(
                                    label: 'Criar rodada',
                                    icon: Icons.add,
                                    onPressed: () => context.go(
                                      '/rounds/new',
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
                                        (r) => r.name
                                            .toLowerCase()
                                            .contains(query),
                                      )
                                      .toList(growable: false);

                              return AppLayout.content(
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 16, 16, 0),
                                      child: Row(
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
                                              '${items.length == 1 ? 'rodada' : 'rodadas'}',
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
                                    ),
                                    Expanded(
                                      child: filtered.isEmpty
                                          ? const AppEmptyState(
                                              message:
                                                  'Nenhuma rodada encontrada',
                                              icon: Icons.search_off,
                                            )
                                          : LayoutBuilder(
                                              builder:
                                                  (context, constraints) {
                                                final columns =
                                                    constraints.maxWidth >= 600
                                                        ? 2
                                                        : 1;
                                                return GridView.builder(
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
                                                    final round =
                                                        filtered[index];
                                                    return _roundCard(
                                                        context, round);
                                                  },
                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                    : const AppEmptyState(
                        message: 'Nenhuma rodada cadastrada',
                        icon: Icons.format_list_numbered,
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
                      color: AppColors.primary,
                    ),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      round.type.label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
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
