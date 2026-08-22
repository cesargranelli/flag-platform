import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../widgets/app_back_button.dart';
import '../widgets/edit_restriction_note.dart';
import 'division_form_screen.dart';

/// GestÃ£o de conferÃªncias e divisÃµes por campeonato.
///
/// Redesign da issue #218: cabeÃ§alho de contexto (campeonato selecionado,
/// status, contadores e seletor), conferÃªncias como cards expansÃ­veis com
/// suas divisÃµes e aÃ§Ãµes de criaÃ§Ã£o unificadas nos cabeÃ§alhos de seÃ§Ã£o.
/// O fluxo continua: campeonato â†’ conferÃªncias â†’ divisÃµes (migraÃ§Ã£o V24).
class GroupingsScreen extends ConsumerWidget {
  const GroupingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitions = ref.watch(competitionsProvider);
    final selectedCompetitionId = ref.watch(selectedCompetitionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ConferÃªncias e divisÃµes'),
        leading: const AppBackButton(fallbackRoute: '/'),
      ),
      body: competitions.when(
        loading: () => const AppLoading(message: 'Carregando campeonatos...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'NÃ£o foi possÃ­vel carregar os campeonatos',
          onRetry: () => ref.invalidate(competitionsProvider),
        ),
        data: (compItems) {
          if (compItems.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhum campeonato cadastrado. '
                  'Crie um campeonato para organizar conferÃªncias e divisÃµes.',
              icon: Icons.emoji_events_outlined,
            );
          }
          // O id selecionado pode estar obsoleto (ex.: campeonato removido
          // em outra sessÃ£o); nesse caso cai para o primeiro disponÃ­vel.
          var selected = compItems.first;
          for (final c in compItems) {
            if (c.id == selectedCompetitionId) {
              selected = c;
              break;
            }
          }
          return _GroupingsBody(competitions: compItems, competition: selected);
        },
      ),
    );
  }
}

/// Corpo da tela para o campeonato selecionado.
class _GroupingsBody extends ConsumerWidget {
  const _GroupingsBody({required this.competitions, required this.competition});

  final List<Competition> competitions;
  final Competition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conferences = ref.watch(conferencesProvider(competition.id));
    final divisions = ref.watch(divisionsProvider(competition.id));
    // Issue #261: criação/edição de conferências e divisões exige ser
    // criador do campeonato ou ADMIN (o backend já bloqueia as escritas).
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider).state.user,
      competition,
    );

    return AppLayout.content(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _contextHeader(context, ref, conferences, divisions),
          if (!canEdit)
            const EditRestrictionNote(
              message:
                  'Apenas o criador do campeonato pode gerenciar '
                  'conferências e divisões.',
            ),
          const SizedBox(height: 24),
          _conferencesSection(context, ref, conferences, divisions, canEdit),
          const SizedBox(height: 24),
          _standaloneDivisionsSection(context, ref, divisions, canEdit),
        ],
      ),
    );
  }

  /// CabeÃ§alho de contexto: campeonato, status, contadores e seletor.
  Widget _contextHeader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Conference>> conferences,
    AsyncValue<List<Division>> divisions,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
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
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _countersLabel(conferences, divisions),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                child: DropdownButtonFormField<String>(
                  initialValue: competition.id,
                  decoration: const InputDecoration(
                    labelText: 'Campeonato',
                    border: OutlineInputBorder(),
                  ),
                  items: competitions
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
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

  /// SeÃ§Ã£o de conferÃªncias: tÃ­tulo, aÃ§Ã£o primÃ¡ria e lista expansÃ­vel.
  Widget _conferencesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Conference>> conferences,
    AsyncValue<List<Division>> divisions,
    bool canEdit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'ConferÃªncias',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (canEdit)
              FilledButton.icon(
                onPressed: () =>
                    context.push('/conferences/new', extra: competition.id),
                icon: const Icon(Icons.add),
                label: const Text('Nova conferÃªncia'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        conferences.when(
          loading: () =>
              const AppLoading(message: 'Carregando conferÃªncias...'),
          error: (error, stackTrace) => AppErrorState(
            message: 'NÃ£o foi possÃ­vel carregar as conferÃªncias',
            onRetry: () => ref.invalidate(conferencesProvider(competition.id)),
          ),
          data: (confItems) {
            if (confItems.isEmpty) {
              return const AppEmptyState(
                message: 'Nenhuma conferÃªncia criada. '
                    'Crie a primeira para organizar seu campeonato.',
                icon: Icons.account_tree_outlined,
              );
            }
            final divItems = divisions.valueOrNull ?? const <Division>[];
            return Column(
              children: [
                for (final conf in confItems)
                  _ConferenceCard(
                    key: ValueKey(conf.id),
                    conference: conf,
                    divisions: divItems
                        .where((d) => d.conferenceId == conf.id)
                        .toList(),
                    divisionsLoading: divisions.isLoading,
                    divisionsFailed: divisions.hasError,
                    // Com uma Ãºnica conferÃªncia, abre-a para dar contexto
                    // imediato da estrutura (critÃ©rio da issue #218).
                    initiallyExpanded: confItems.length == 1,
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

  /// SeÃ§Ã£o de divisÃµes sem conferÃªncia vinculada.
  Widget _standaloneDivisionsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Division>> divisions,
    bool canEdit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'DivisÃµes sem conferÃªncia',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (canEdit)
              TextButton.icon(
                onPressed: () => context.push(
                  '/divisions/new',
                  extra: DivisionFormArgs(competitionId: competition.id),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar divisÃ£o'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: divisions.when(
              loading: () =>
                  const AppLoading(message: 'Carregando divisÃµes...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'NÃ£o foi possÃ­vel carregar as divisÃµes',
                onRetry: () =>
                    ref.invalidate(divisionsProvider(competition.id)),
              ),
              data: (divItems) {
                final standalone = divItems
                    .where((d) => d.conferenceId == null)
                    .toList();
                if (standalone.isEmpty) {
                  return const AppEmptyState(
                    message: 'Nenhuma divisÃ£o sem conferÃªncia. '
                        'Use "Adicionar divisÃ£o" para criar uma.',
                    icon: Icons.subdirectory_arrow_right,
                  );
                }
                return Column(
                  children: [
                    for (final division in standalone)
                      _divisionRow(context, division, canEdit: canEdit),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Chip de status do campeonato (mesmo padrÃ£o da tela de detalhe).
  Widget _statusChip(CompetitionStatus status) {
    final color = switch (status) {
      CompetitionStatus.draft => AppColors.textSecondary,
      CompetitionStatus.published => AppColors.success,
      CompetitionStatus.finished => AppColors.danger,
      CompetitionStatus.disabled => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(fontSize: 13, color: color),
      ),
    );
  }

  String _statusLabel(CompetitionStatus status) => switch (status) {
    CompetitionStatus.draft => 'Rascunho',
    CompetitionStatus.published => 'Publicado',
    CompetitionStatus.finished => 'Encerrado',
    CompetitionStatus.disabled => 'Desativado',
  };

  /// RÃ³tulo de contadores do cabeÃ§alho ("X conferÃªncias Â· Y divisÃµes").
  String _countersLabel(
    AsyncValue<List<Conference>> conferences,
    AsyncValue<List<Division>> divisions,
  ) {
    if (conferences.isLoading || divisions.isLoading) {
      return 'Carregando estrutura...';
    }
    final confPart = _countPart(
      conferences.valueOrNull?.length,
      'conferÃªncia',
      'conferÃªncias',
    );
    final divPart = _countPart(
      divisions.valueOrNull?.length,
      'divisÃ£o',
      'divisÃµes',
    );
    return '$confPart Â· $divPart';
  }
}

/// Card expansÃ­vel de uma conferÃªncia com suas divisÃµes.
///
/// O estado de expansÃ£o vive aqui (chaveada pelo id da conferÃªncia), entÃ£o
/// sobrevive a refetches dos providers sem resetar o que o usuÃ¡rio abriu.
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CabeÃ§alho clicÃ¡vel: expande/recolhe as divisÃµes.
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_tree_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      conference.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _divisionsMeta(context),
                  if (widget.canEdit)
                    IconButton(
                      tooltip: 'Editar conferÃªncia',
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => context.push(
                        '/conferences/${conference.id}/edit',
                        extra: conference,
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
                            'Nenhuma divisÃ£o nesta conferÃªncia.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        for (final division in widget.divisions)
                          _divisionRow(
                            context,
                            division,
                            canEdit: widget.canEdit,
                          ),
                      if (widget.canEdit)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => context.push(
                              '/divisions/new',
                              extra: DivisionFormArgs(
                                competitionId: widget.competitionId,
                                conferenceId: conference.id,
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar divisÃ£o'),
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

  /// Contagem de divisÃµes como chip/meta no cabeÃ§alho do card.
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
      label = 'â€”';
    } else if (widget.divisions.isEmpty) {
      label = 'Sem divisÃµes';
    } else {
      label = _plural(widget.divisions.length, 'divisÃ£o', 'divisÃµes');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grayFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}

/// Linha de divisÃ£o com Ã­cone de hierarquia e aÃ§Ã£o de ediÃ§Ã£o.
Widget _divisionRow(
  BuildContext context,
  Division division, {
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
        if (canEdit)
          IconButton(
            tooltip: 'Editar divisÃ£o',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () =>
                context.push('/divisions/${division.id}/edit', extra: division),
          ),
      ],
    ),
  );
}

/// Contagem com plural correto em portuguÃªs.
String _plural(int count, String singular, String plural) =>
    '$count ${count == 1 ? singular : plural}';

/// Parte do rÃ³tulo de contadores; [count] nulo indica falha de carregamento.
String _countPart(int? count, String singular, String plural) =>
    count == null ? '$plural indisponÃ­veis' : _plural(count, singular, plural);
