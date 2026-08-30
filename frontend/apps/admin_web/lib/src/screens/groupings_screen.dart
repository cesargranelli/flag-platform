import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../widgets/app_screen.dart';
import '../widgets/club_assignment_modal.dart';
import '../widgets/conference_form_modal.dart';
import '../widgets/division_form_modal.dart';
import '../widgets/edit_restriction_note.dart';

/// Gestão de conferências e divisões por campeonato.
///
/// Redesign da issue #218: cabeçalho de contexto (campeonato selecionado,
/// status, contadores e seletor), conferências como cards expansíveis com
/// suas divisões e ações de criação unificadas nos cabeçalhos de seção.
/// O fluxo continua: campeonato → conferências → divisões (migração V24).
///
/// Issue #258: criação/edição de conferências/divisões e associação de
/// clubes acontecem em modais (sem rotas dedicadas).
class GroupingsScreen extends ConsumerWidget {
  const GroupingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitions = ref.watch(competitionsProvider);
    final selectedCompetitionId = ref.watch(selectedCompetitionProvider);

    return AppScreen(
      title: 'Conferências e divisões',
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem(AppStrings.competitions, route: '/competitions'),
        BreadcrumbItem('Conferências e divisões'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          competitions.when(
            loading: () =>
                const AppLoading(message: 'Carregando campeonatos...'),
            error: (error, stackTrace) => AppErrorState(
              message: 'Não foi possível carregar os campeonatos',
              onRetry: () => ref.invalidate(competitionsProvider),
            ),
            data: (compItems) {
              if (compItems.isEmpty) {
                return KicksterEmptyState(
                  icon: Icons.emoji_events_outlined,
                  message: 'Nenhum campeonato cadastrado',
                  description:
                      'Crie um campeonato para organizar conferências e divisões.',
                  action: KicksterButton(
                    label: 'Criar campeonato',
                    icon: Icons.add,
                    onPressed: () => context.go('/competitions/new'),
                  ),
                );
              }
              // O id selecionado pode estar obsoleto (ex.: campeonato removido
              // em outra sessão); nesse caso cai para o primeiro disponível.
              var selected = compItems.first;
              for (final c in compItems) {
                if (c.id == selectedCompetitionId) {
                  selected = c;
                  break;
                }
              }
              return _GroupingsBody(
                competitions: compItems,
                competition: selected,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Corpo da tela para o campeonato selecionado.
class _GroupingsBody extends ConsumerStatefulWidget {
  const _GroupingsBody({required this.competitions, required this.competition});

  final List<Competition> competitions;
  final Competition competition;

  @override
  ConsumerState<_GroupingsBody> createState() => _GroupingsBodyState();
}

class _GroupingsBodyState extends ConsumerState<_GroupingsBody> {
  final _searchController = TextEditingController();
  String _query = '';

  Competition get competition => widget.competition;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conferences = ref.watch(conferencesProvider(competition.id));
    final divisions = ref.watch(divisionsProvider(competition.id));
    // Issue #261: criação/edição de conferências e divisões exige ser
    // criador do campeonato ou ADMIN (o backend já bloqueia as escritas).
    // Issue #305: e apenas com o campeonato em DRAFT — publicado/encerrado
    // tem a estrutura travada (somente leitura).
    final canEdit =
        canEditCompetition(
          ref.watch(authControllerProvider.select((a) => a.state.user)),
          competition,
        ) &&
        competition.status == CompetitionStatus.draft;
    final lockedByStatus = competition.status != CompetitionStatus.draft;
    final query = _query.trim().toLowerCase();

    return AppLayout.content(
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              if (query.isNotEmpty)
                Text(
                  '${_filteredCount(conferences, divisions, query)} '
                  '${_filteredCount(conferences, divisions, query) == 1 ? 'resultado' : 'resultados'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                Text(
                  _countersLabel(conferences, divisions),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: 280,
                child: KicksterSearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _contextHeader(context, ref, conferences, divisions),
          if (!canEdit && !lockedByStatus)
            const EditRestrictionNote(
              message:
                  'Apenas o criador do campeonato pode gerenciar '
                  'conferências e divisões.',
            ),
          if (lockedByStatus)
            const EditRestrictionNote(
              message:
                  'Campeonato publicado — conferências, divisões e grupos '
                  'estão travados.',
            ),
          const SizedBox(height: 24),
          _conferencesSection(
            context,
            ref,
            conferences,
            divisions,
            canEdit,
            query,
          ),
          const SizedBox(height: 24),
          _standaloneDivisionsSection(context, ref, divisions, canEdit, query),
        ],
      ),
    );
  }

  /// Total de itens visíveis (conferências + divisões) para o contador.
  int _filteredCount(
    AsyncValue<List<Conference>> conferences,
    AsyncValue<List<Division>> divisions,
    String query,
  ) {
    if (query.isEmpty) return 0;
    final confItems = conferences.valueOrNull ?? const <Conference>[];
    final divItems = divisions.valueOrNull ?? const <Division>[];
    final confCount = confItems
        .where((c) => c.name.toLowerCase().contains(query))
        .length;
    final divCount = divItems
        .where((d) => d.name.toLowerCase().contains(query))
        .length;
    return confCount + divCount;
  }

  /// Cabeçalho de contexto: campeonato, status, contadores e seletor.
  Widget _contextHeader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Conference>> conferences,
    AsyncValue<List<Division>> divisions,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        competition.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _countersLabel(conferences, divisions),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _statusChip(competition.status),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: KicksterDropdown<String>(
                  label: 'Campeonato',
                  value: competition.id,
                  items: widget.competitions
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
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(selectedCompetitionProvider.notifier).state =
                          value;
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Seção de conferências: título, ação primária e lista expansível.
  Widget _conferencesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Conference>> conferences,
    AsyncValue<List<Division>> divisions,
    bool canEdit,
    String query,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Conferências',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (canEdit)
              KicksterButton(
                label: 'Nova conferência',
                icon: Icons.add,
                onPressed: () => showConferenceFormModal(
                  context,
                  competitionId: competition.id,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        conferences.when(
          loading: () =>
              const AppLoading(message: 'Carregando conferências...'),
          error: (error, stackTrace) => AppErrorState(
            message: 'Não foi possível carregar as conferências',
            onRetry: () => ref.invalidate(conferencesProvider(competition.id)),
          ),
          data: (confItems) {
            final filteredConf = query.isEmpty
                ? confItems
                : confItems
                      .where((c) => c.name.toLowerCase().contains(query))
                      .toList(growable: false);
            if (filteredConf.isEmpty && query.isNotEmpty) {
              return const AppEmptyState(
                message: 'Nenhuma conferência encontrada',
                icon: Icons.search_off,
              );
            }
            if (filteredConf.isEmpty) {
              return const AppEmptyState(
                message:
                    'Nenhuma conferência criada. '
                    'Crie a primeira para organizar seu campeonato.',
                icon: Icons.account_tree_outlined,
              );
            }
            final divItems = divisions.valueOrNull ?? const <Division>[];
            return Column(
              children: [
                for (final conf in filteredConf)
                  _ConferenceCard(
                    key: ValueKey(conf.id),
                    conference: conf,
                    divisions: divItems
                        .where((d) => d.conferenceId == conf.id)
                        .where(
                          (d) =>
                              query.isEmpty ||
                              d.name.toLowerCase().contains(query),
                        )
                        .toList(),
                    divisionsLoading: divisions.isLoading,
                    divisionsFailed: divisions.hasError,
                    // Com uma única conferência, abre-a para dar contexto
                    // imediato da estrutura (critério da issue #218).
                    initiallyExpanded: filteredConf.length == 1,
                    competitionId: competition.id,
                    canEdit: canEdit,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Seção de divisões sem conferência vinculada.
  Widget _standaloneDivisionsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Division>> divisions,
    bool canEdit,
    String query,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Divisões sem conferência',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (canEdit)
              KicksterButton(
                label: 'Adicionar divisão',
                icon: Icons.add,
                variant: KicksterButtonVariant.outline,
                onPressed: () => showDivisionFormModal(
                  context,
                  competitionId: competition.id,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          elevation: 1,
          shadowColor: AppColors.black.withValues(alpha: 0.08),
          color: AppColors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.line, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: divisions.when(
              loading: () =>
                  const AppLoading(message: 'Carregando divisões...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar as divisões',
                onRetry: () =>
                    ref.invalidate(divisionsProvider(competition.id)),
              ),
              data: (divItems) {
                final standalone = divItems
                    .where((d) => d.conferenceId == null)
                    .where(
                      (d) =>
                          query.isEmpty || d.name.toLowerCase().contains(query),
                    )
                    .toList();
                if (standalone.isEmpty) {
                  if (query.isNotEmpty) {
                    return const AppEmptyState(
                      message: 'Nenhuma divisão encontrada',
                      icon: Icons.search_off,
                    );
                  }
                  return const AppEmptyState(
                    message:
                        'Nenhuma divisão sem conferência. '
                        'Use "Adicionar divisão" para criar uma.',
                    icon: Icons.subdirectory_arrow_right,
                  );
                }
                return Column(
                  children: [
                    for (final division in standalone)
                      _divisionRow(
                        context,
                        division,
                        competitionId: competition.id,
                        canEdit: canEdit,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Chip de status do campeonato (mesmo padrão da tela de detalhe).
  Widget _statusChip(CompetitionStatus status) {
    final color = switch (status) {
      CompetitionStatus.draft => AppColors.textSecondary,
      CompetitionStatus.published => AppColors.success,
      CompetitionStatus.finished => AppColors.danger,
      CompetitionStatus.disabled => AppColors.textSecondary,
    };
    return KicksterBadge(label: _statusLabel(status), color: color);
  }

  String _statusLabel(CompetitionStatus status) => switch (status) {
    CompetitionStatus.draft => 'Rascunho',
    CompetitionStatus.published => 'Publicado',
    CompetitionStatus.finished => 'Encerrado',
    CompetitionStatus.disabled => 'Desativado',
  };

  /// Rótulo de contadores do cabeçalho ("X conferências · Y divisões").
  String _countersLabel(
    AsyncValue<List<Conference>> conferences,
    AsyncValue<List<Division>> divisions,
  ) {
    if (conferences.isLoading || divisions.isLoading) {
      return 'Carregando estrutura...';
    }
    final confPart = _countPart(
      conferences.valueOrNull?.length,
      'conferência',
      'conferências',
    );
    final divPart = _countPart(
      divisions.valueOrNull?.length,
      'divisão',
      'divisões',
    );
    return '$confPart · $divPart';
  }
}

/// Card expansível de uma conferência com suas divisões.
///
/// O estado de expansão vive aqui (chaveada pelo id da conferência), então
/// sobrevive a refetches dos providers sem resetar o que o usuário abriu.
class _ConferenceCard extends StatefulWidget {
  const _ConferenceCard({
    super.key,
    required this.conference,
    required this.divisions,
    required this.divisionsLoading,
    required this.divisionsFailed,
    required this.initiallyExpanded,
    required this.competitionId,
    required this.canEdit,
  });

  final Conference conference;
  final List<Division> divisions;
  final bool divisionsLoading;
  final bool divisionsFailed;
  final bool initiallyExpanded;
  final String competitionId;

  /// Issue #261: oculta ações de edição quando o usuário não é o criador
  /// do campeonato nem ADMIN.
  final bool canEdit;

  @override
  State<_ConferenceCard> createState() => _ConferenceCardState();
}

class _ConferenceCardState extends State<_ConferenceCard> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final conference = widget.conference;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho clicável: expande/recolhe as divisões.
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_tree_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      conference.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _divisionsMeta(context),
                  if (widget.canEdit)
                    IconButton(
                      tooltip: 'Editar conferência',
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => showConferenceFormModal(
                        context,
                        competitionId: widget.competitionId,
                        conference: conference,
                      ),
                    ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOut,
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.divisions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Nenhuma divisão nesta conferência.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        for (final division in widget.divisions)
                          _divisionRow(
                            context,
                            division,
                            competitionId: widget.competitionId,
                            canEdit: widget.canEdit,
                          ),
                      if (widget.canEdit)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: KicksterButton(
                            label: 'Adicionar divisão',
                            icon: Icons.add,
                            variant: KicksterButtonVariant.text,
                            onPressed: () => showDivisionFormModal(
                              context,
                              competitionId: widget.competitionId,
                              initialConferenceId: conference.id,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Contagem de divisões como chip/meta no cabeçalho do card.
  Widget _divisionsMeta(BuildContext context) {
    if (widget.divisionsLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final String label;
    if (widget.divisionsFailed) {
      label = '—';
    } else if (widget.divisions.isEmpty) {
      label = 'Sem divisões';
    } else {
      label = _plural(widget.divisions.length, 'divisão', 'divisões');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grayFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

/// Linha de divisão com ícone de hierarquia e ações de edição/associação.
Widget _divisionRow(
  BuildContext context,
  Division division, {
  required String competitionId,
  required bool canEdit,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        const SizedBox(width: 8),
        const Icon(
          Icons.subdirectory_arrow_right,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            division.name,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (canEdit) ...[
          IconButton(
            tooltip: 'Associar clubes',
            icon: const Icon(Icons.group_add_outlined, size: 20),
            onPressed: () => showClubAssignmentModal(
              context,
              competitionId: competitionId,
              division: division,
            ),
          ),
          IconButton(
            tooltip: 'Editar divisão',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => showDivisionFormModal(
              context,
              competitionId: competitionId,
              division: division,
            ),
          ),
        ],
      ],
    ),
  );
}

/// Contagem com plural correto em português.
String _plural(int count, String singular, String plural) =>
    '$count ${count == 1 ? singular : plural}';

/// Parte do rótulo de contadores; [count] nulo indica falha de carregamento.
String _countPart(int? count, String singular, String plural) =>
    count == null ? '$plural indisponíveis' : _plural(count, singular, plural);
