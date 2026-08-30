import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../widgets/app_entity_list_screen.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);

    final compItems = competitions.valueOrNull ?? const [];
    // P4 #461: campeonato efetivo = selecionado ?? primeiro da lista.
    final effectiveComp = ref.watch(effectiveCompetitionProvider);

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
      ref.watch(authControllerProvider.select((a) => a.state.user)),
      selectedCompetitionObj,
    );
    final canManage = canEdit && isDraft;

    return AppScreen(
      title: 'Rodadas',
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem(AppStrings.rounds, route: '/rounds'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Actions
          Row(
            children: [
              const Spacer(),
              if (effectiveComp != null && canManage)
                KicksterButton(
                  label: 'Novo',
                  icon: Icons.add,
                  onPressed: () =>
                      context.go('/rounds/new', extra: effectiveComp),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Conteúdo (Expanded para dar altura finita ao grid)
          Expanded(
            child: competitions.when(
              loading: () =>
                  const AppLoading(message: 'Carregando campeonatos...'),
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
                    Column(
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
                            ref
                                .read(selectedCompetitionProvider.notifier)
                                .state = value;
                            ref.read(selectedRoundProvider.notifier).state =
                                null;
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
                    // Grid em altura finita (Expanded) → virtualização real.
                    const SizedBox(height: 16),
                    Expanded(
                      child: effectiveComp != null
                          ? ref
                                .watch(roundsProvider(effectiveComp))
                                .when(
                                  loading: () => const AppLoading(
                                    message: 'Carregando rodadas...',
                                  ),
                                  error: (error, stackTrace) =>
                                      AppErrorState(
                                    message:
                                        'Não foi possível carregar as rodadas',
                                    onRetry: () => ref.invalidate(
                                        roundsProvider(effectiveComp)),
                                  ),
                                  data: (items) {
                                    if (items.isEmpty) {
                                      return KicksterEmptyState(
                                        icon: Icons.format_list_numbered,
                                        message:
                                            'Nenhuma rodada cadastrada',
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
                                    return AppEntityListScreen<Round>(
                                      items: items,
                                      cardBuilder: (round) =>
                                          _roundCard(context, round),
                                      searchField: _searchController,
                                      countLabel: 'rodadas',
                                      countLabelSingular: 'rodada',
                                      emptyMessage:
                                          'Nenhuma rodada encontrada',
                                      gridPadding:
                                          const EdgeInsets.all(16),
                                      filter: (all, query) => query.isEmpty
                                          ? all
                                          : all
                                              .where(
                                                (r) => r.name
                                                    .toLowerCase()
                                                    .contains(query),
                                              )
                                              .toList(growable: false),
                                    );
                                  },
                                )
                          : KicksterEmptyState(
                              icon: Icons.format_list_numbered,
                              message: 'Nenhuma rodada cadastrada',
                              description:
                                  'Crie um campeonato para adicionar rodadas.',
                              action: KicksterButton(
                                label: 'Criar campeonato',
                                icon: Icons.add,
                                onPressed: () =>
                                    context.go('/competitions/new'),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundCard(BuildContext context, Round round) {
    return Card(
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
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
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${round.number}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
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
                        color: AppColors.textPrimary,
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
