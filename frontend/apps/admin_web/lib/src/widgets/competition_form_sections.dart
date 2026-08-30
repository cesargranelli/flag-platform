/// Seções do formulário de campeonato compartilhadas entre criação e edição
/// (#460). Cada seção recebe o [CompetitionFormController] e os parâmetros
/// que preservam as divergências legítimas entre as duas telas.
library;

import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import 'competition_form_controller.dart';
import 'selectable_card.dart';

// ---------------------------------------------------------------------------
// Helpers de UI (extraídos de _section/_errorBanner/_groupLabel/_groupError/
// _hint/_removableChip/_summaryChip/_modalityDescription/_modalityIcon/
// _genderIcon das telas create/edit)
// ---------------------------------------------------------------------------

/// Seção empilhada: título (titleMedium) + card (#455).
Widget competitionSection({
  required String title,
  required IconData icon,
  required Widget child,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KicksterSectionTitle(title: title, icon: icon),
      const SizedBox(height: 12),
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
}

/// Banner de erro de API no topo do formulário.
Widget competitionErrorBanner(String message) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.danger.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.danger),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.danger),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    ),
  );
}

/// Rótulo de grupo das seções (título do bloco).
Widget _groupLabel(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
  );
}

/// Mensagem de erro de seção (modalidade/categoria).
Widget _groupError(String message) {
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      message,
      style: const TextStyle(fontSize: 12, color: AppColors.danger),
    ),
  );
}

/// Texto de apoio/dica da seção.
Widget _hint(String text) {
  return Text(
    text,
    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
  );
}

/// Chip de resumo com botão de remoção (X), usado nas listas de
/// conferências e divisões/agrupamentos (#341).
Widget _removableChip({
  required String label,
  required IconData icon,
  required VoidCallback onDelete,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.grayFill,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Semantics(
          label: 'Remover $label',
          button: true,
          child: IconButton(
            onPressed: onDelete,
            tooltip: 'Remover',
            icon: const Icon(Icons.close, size: 16),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    ),
  );
}

/// Chip de resumo das escolhas (apenas criação, #455).
Widget _summaryChip(String label, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.grayFill,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

String _modalityDescription(Modality modality) => switch (modality) {
      Modality.flag5x5 => 'Flag sem contato · 5 jogadores',
      Modality.flag8x8 => 'Flag sem contato · 8 jogadores',
      Modality.flag9x9 => 'Flag sem contato · 9 jogadores',
      Modality.fullPads11x11 => 'Tackle com proteção · 11 jogadores',
    };

IconData _modalityIcon(Modality modality) =>
    modality == Modality.fullPads11x11
        ? Icons.shield_outlined
        : Icons.sports_football_outlined;

/// Ícone representativo por gênero — mantém a simetria dos cards (#328).
IconData _genderIcon(Gender gender) => switch (gender) {
      Gender.male => Icons.male,
      Gender.female => Icons.female,
      Gender.mixed => Icons.transgender,
    };

// ---------------------------------------------------------------------------
// Seção 1 — Campeonato: organização, nome e descrição.
// ---------------------------------------------------------------------------

/// Seção 1 — organização, nome e descrição (#455).
///
/// Divergências create/edit preservadas por parâmetros:
/// - [preselectSingle]/[showPreselectedLabel]: create pré-seleciona a única
///   organização disponível e anexa " (pré-selecionada)" ao label (#257);
/// - [dropdownKeyPrefix]: prefixo do `ValueKey` do dropdown (create/edit);
/// - [onOrganizationChanged]: rebuild extra do host após trocar organização
///   (o edit faz `setState(() {})`; o create não).
class CompetitionIdentitySection extends ConsumerStatefulWidget {
  const CompetitionIdentitySection({
    super.key,
    required this.controller,
    this.dropdownKeyPrefix = '',
    this.preselectSingle = false,
    this.showPreselectedLabel = false,
    this.onOrganizationChanged,
  });

  final CompetitionFormController controller;
  final String dropdownKeyPrefix;
  final bool preselectSingle;
  final bool showPreselectedLabel;
  final VoidCallback? onOrganizationChanged;

  @override
  ConsumerState<CompetitionIdentitySection> createState() =>
      _CompetitionIdentitySectionState();
}

class _CompetitionIdentitySectionState
    extends ConsumerState<CompetitionIdentitySection> {
  // Issue #257 (D): com exatamente 1 organização disponível, pré-seleciona.
  void _maybePreselectOrganization(List<Organization> orgs) {
    final c = widget.controller;
    if (c.organizationId.text.isNotEmpty || orgs.length != 1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || c.organizationId.text.isNotEmpty) return;
      setState(() {
        c.populating = true;
        c.organizationId.text = orgs.single.id;
        c.populating = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final organizations = ref.watch(organizationsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        organizations.when(
          loading: () => KicksterDropdown<String>(
            label: 'Organização',
            hint: 'Carregando organizações…',
            items: const <DropdownMenuItem<String>>[],
            onChanged: null,
          ),
          error: (e, s) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.danger),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 20,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Erro ao carregar organizações',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => ref.invalidate(organizationsProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
          data: (orgs) {
            if (widget.preselectSingle) _maybePreselectOrganization(orgs);
            if (orgs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.business_outlined,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nenhuma organização disponível',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              );
            }
            return KicksterDropdown<String>(
              key: ValueKey(
                '${widget.dropdownKeyPrefix}-${c.organizationId.text}',
              ),
              label:
                  'Organização${widget.showPreselectedLabel && orgs.length == 1 ? ' (pré-selecionada)' : ''}',
              value: c.organizationId.text.isEmpty ? null : c.organizationId.text,
              items: orgs
                  .map(
                    (o) => DropdownMenuItem(
                      value: o.id,
                      child: appDropdownItem(
                        organizationTypeIcon(o.organizationType),
                        o.tradeName,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                c.organizationId.text = value ?? '';
                widget.onOrganizationChanged?.call();
              },
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Selecione a organização'
                  : null,
            );
          },
        ),
        const SizedBox(height: 12),
        KicksterInput(
          label: 'Nome',
          controller: c.name,
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Informe o nome'
              : null,
        ),
        const SizedBox(height: 12),
        KicksterInput(
          label: 'Descrição',
          controller: c.description,
          maxLines: 3,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Seção 2 — Modalidade: cards 2x2.
// ---------------------------------------------------------------------------

/// Seção 2 — modalidade (cards 2x2).
///
/// O título difere entre as telas: create usa "Escolha a modalidade"
/// (default) e edit usa "Modalidade".
class CompetitionModalitySection extends ConsumerWidget {
  const CompetitionModalitySection({
    super.key,
    required this.controller,
    this.title = 'Escolha a modalidade',
  });

  final CompetitionFormController controller;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _groupLabel(title),
        const SizedBox(height: 4),
        _hint('Formato de jogo do campeonato'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 480;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final modality in Modality.values)
                  SizedBox(
                    width: isWide
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth,
                    child: SelectableCard(
                      label: modality.label,
                      description: _modalityDescription(modality),
                      icon: _modalityIcon(modality),
                      selected: c.modality == modality,
                      onTap: () => c.selectModality(modality),
                    ),
                  ),
              ],
            );
          },
        ),
        if (c.modalityError != null) _groupError(c.modalityError!),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Seção 3 — Categoria: gênero (cards) + faixa etária (chips).
// ---------------------------------------------------------------------------

/// Seção 3 — gênero (cards) + faixa etária (chips).
class CompetitionCategorySection extends ConsumerWidget {
  const CompetitionCategorySection({
    super.key,
    required this.controller,
  });

  final CompetitionFormController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _groupLabel('Gênero'),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 480;
            final cardWidth = isWide
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final gender in Gender.values)
                  SizedBox(
                    width: cardWidth,
                    child: SelectableCard(
                      label: gender.label,
                      icon: _genderIcon(gender),
                      selected: c.gender == gender,
                      onTap: () => c.selectGender(gender),
                    ),
                  ),
              ],
            );
          },
        ),
        if (c.categoryError != null && c.gender == null)
          _groupError('Selecione o gênero'),
        const SizedBox(height: 20),
        _groupLabel('Faixa etária'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final ageGroup in AgeGroup.values)
              SelectableChip(
                label: ageGroup.label,
                selected: c.ageGroup == ageGroup,
                onTap: () => c.selectAgeGroup(ageGroup),
              ),
          ],
        ),
        if (c.categoryError != null && c.gender != null && c.ageGroup == null)
          _groupError(c.categoryError!),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Seção 4 — Temporada: datas opcionais (+ resumo apenas na criação).
// ---------------------------------------------------------------------------

/// Seção 4 — período da temporada (datas opcionais).
///
/// [showSummary] (apenas create) adiciona o bloco "Resumo" com os chips das
/// escolhas e a dica sobre salvar como rascunho (#455).
class CompetitionSeasonSection extends ConsumerWidget {
  const CompetitionSeasonSection({
    super.key,
    required this.controller,
    this.showSummary = false,
    this.isMounted,
  });

  final CompetitionFormController controller;
  final bool showSummary;

  /// Guard `mounted` do host para o date picker (preserva o comportamento
  /// original de não aplicar a data após o widget ser desmontado).
  final bool Function()? isMounted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _groupLabel('Período da temporada (opcional)'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: KicksterInput(
                label: 'Início (opcional)',
                controller: c.startDate,
                readOnly: true,
                onTap: () =>
                    c.pickDate(context, c.startDate, isMounted: isMounted),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KicksterInput(
                label: 'Fim (opcional)',
                controller: c.endDate,
                readOnly: true,
                onTap: () => c.pickDate(
                  context,
                  c.endDate,
                  minDate: c.parsedStartDate,
                  isMounted: isMounted,
                ),
                suffixIcon: const Icon(Icons.calendar_today),
                validator: (value) {
                  final start = c.parsedStartDate;
                  final end = value == null || value.isEmpty
                      ? null
                      : DateTime.tryParse(value);
                  if (start != null && end != null && end.isBefore(start)) {
                    return 'Data final deve ser maior ou igual à data inicial';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        if (showSummary) ...[
          const SizedBox(height: 20),
          _groupLabel('Resumo'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _summaryChip(
                c.name.text.trim().isEmpty ? 'Campeonato' : c.name.text.trim(),
                Icons.emoji_events_outlined,
              ),
              if (c.modality != null)
                _summaryChip(c.modality!.label, Icons.sports_football_outlined),
              if (c.gender != null)
                _summaryChip(c.gender!.label, Icons.groups_outlined),
              if (c.ageGroup != null)
                _summaryChip(c.ageGroup!.label, Icons.cake_outlined),
            ],
          ),
          const SizedBox(height: 16),
          _hint(
            'Ao criar, o campeonato é salvo como rascunho e você poderá '
            'configurar conferências, divisões ou grupos abaixo.',
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Seção 5 — Conferências (#304/#345): criar/listar, com declínio.
// ---------------------------------------------------------------------------

/// Seção 5 — conferências: criar/listar com declínio.
///
/// [competitionId] `null` (create antes do rascunho) mostra a dica "Crie o
/// campeonato acima..." e desabilita o input/botão — no edit nunca é null.
class CompetitionConferencesSection extends ConsumerWidget {
  const CompetitionConferencesSection({
    super.key,
    required this.controller,
    required this.competitionId,
  });

  final CompetitionFormController controller;

  /// Id do campeonato — `null` no create antes do rascunho (estrutura travada).
  final String? competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = controller;
    final conferences = competitionId == null
        ? const AsyncValue<List<Conference>>.data([])
        : ref.watch(conferencesProvider(competitionId!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (competitionId == null) ...[
          _hint(
            'Crie o campeonato acima para habilitar a configuração '
            'da estrutura.',
          ),
          const SizedBox(height: 12),
        ],
        _groupLabel('Conferências'),
        const SizedBox(height: 4),
        _hint(
          'Opcional. Use conferências para separar grandes blocos do '
          'campeonato (ex.: Conferência Norte/Sul).',
        ),
        const SizedBox(height: 12),
        if (c.declinedConferences) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grayFill),
              color: AppColors.grayFill.withValues(alpha: 0.5),
            ),
            child: const Text(
              'Este campeonato não usará conferências.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
          KicksterButton(
            label: 'Usar conferências',
            icon: Icons.undo,
            variant: KicksterButtonVariant.text,
            onPressed: c.undoDeclineConferences,
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: KicksterInput(
                  label: 'Nome da conferência',
                  controller: c.conferenceName,
                  enabled: competitionId != null,
                  onFieldSubmitted: (_) => c.addConference(),
                ),
              ),
              const SizedBox(width: 12),
              KicksterButton(
                label: 'Adicionar',
                icon: Icons.add,
                onPressed: competitionId == null || c.submitting
                    ? null
                    : c.addConference,
              ),
            ],
          ),
          const SizedBox(height: 12),
          conferences.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, s) => const Text(
              'Não foi possível carregar as conferências.',
              style: TextStyle(color: AppColors.danger),
            ),
            data: (items) => items.isEmpty
                ? _hint('Nenhuma conferência adicionada ainda.')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final conference in items)
                        _removableChip(
                          label: conference.name,
                          icon: Icons.account_tree_outlined,
                          onDelete: () => c.removeConference(conference),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          KicksterButton(
            label: 'Este campeonato não usa conferências',
            variant: KicksterButtonVariant.outline,
            onPressed: c.declineConferences,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Seção 6 — Agrupamento (#304/#338/#345): Divisões OU Grupos, com declínio.
// ---------------------------------------------------------------------------

/// Seção 6 — agrupamento: Divisões OU Grupos, com declínio.
///
/// [competitionId] `null` (create antes do rascunho) mostra a dica e
/// desabilita input/botão — no edit nunca é null.
class CompetitionStructureSection extends ConsumerWidget {
  const CompetitionStructureSection({
    super.key,
    required this.controller,
    required this.competitionId,
  });

  final CompetitionFormController controller;

  /// Id do campeonato — `null` no create antes do rascunho (estrutura travada).
  final String? competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = controller;
    final divisions = competitionId == null
        ? const AsyncValue<List<Division>>.data([])
        : ref.watch(divisionsProvider(competitionId!));
    final conferences = competitionId == null
        ? const AsyncValue<List<Conference>>.data([])
        : ref.watch(conferencesProvider(competitionId!));
    final conferenceItems = conferences.valueOrNull ?? const <Conference>[];
    final hasAddedItems =
        (divisions.valueOrNull ?? const <Division>[]).isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (competitionId == null) ...[
          _hint(
            'Crie o campeonato acima para habilitar a configuração '
            'da estrutura.',
          ),
          const SizedBox(height: 12),
        ],
        _groupLabel('Como os clubes serão agrupados?'),
        const SizedBox(height: 4),
        _hint(
          'Divisões e Grupos têm o mesmo funcionamento — muda apenas o nome.',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return Row(
              children: [
                for (final type in GroupingType.values) ...[
                  if (type != GroupingType.values.first)
                    const SizedBox(width: 12),
                  SizedBox(
                    width: cardWidth,
                    child: SelectableCard(
                      label: type.label,
                      description:
                          'Agrupamento por ${type.label.toLowerCase()}',
                      icon: Icons.account_tree_outlined,
                      selected: c.groupingChoice == type,
                      enabled: !hasAddedItems,
                      onTap: () => c.selectGrouping(type),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        if (c.declinedStructure)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grayFill),
              color: AppColors.grayFill.withValues(alpha: 0.5),
            ),
            child: const Text(
              'Este campeonato não usará divisões nem grupos.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else if (c.groupingChoice == null)
          _hint(
            'Selecione Divisões ou Grupos acima, ou declare que este '
            'campeonato não usará agrupamentos.',
          )
        else ...[
          if (conferenceItems.isNotEmpty) ...[
            KicksterDropdown<String>(
              key: ValueKey('division-conf-${c.conferenceId ?? ''}'),
              label: 'Conferência',
              value: c.conferenceId ?? '',
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Sem conferência'),
                ),
                for (final conference in conferenceItems)
                  DropdownMenuItem(
                    value: conference.id,
                    child: Text(conference.name),
                  ),
              ],
              onChanged: c.selectConference,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: KicksterInput(
                  label: 'Nome (${c.groupingChoice})',
                  controller: c.divisionName,
                  enabled: competitionId != null,
                  onFieldSubmitted: (_) => c.addDivision(),
                ),
              ),
              const SizedBox(width: 12),
              KicksterButton(
                label: 'Adicionar',
                icon: Icons.add,
                onPressed:
                    competitionId == null || c.submitting ? null : c.addDivision,
              ),
            ],
          ),
          const SizedBox(height: 12),
          divisions.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, s) => Text(
              'Não foi possível carregar as ${c.itemLabelLower}.',
              style: const TextStyle(color: AppColors.danger),
            ),
            data: (items) => items.isEmpty
                ? _hint('Nenhum item adicionado ainda.')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final division in items)
                        _removableChip(
                          label: division.name,
                          icon: Icons.folder_outlined,
                          onDelete: () => c.removeDivision(division),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          KicksterButton(
            label: 'Não usar divisões nem grupos',
            variant: KicksterButtonVariant.outline,
            onPressed: c.declineStructure,
          ),
        ],
      ],
    );
  }
}