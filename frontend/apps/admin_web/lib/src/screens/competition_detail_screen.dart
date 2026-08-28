import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Detalhe de um campeonato em sessões espelhando o wizard (#306),
/// com navegação por cards no topo (#316): tocar em uma sessão troca o
/// bloco exibido — a tela mostra APENAS o conteúdo da sessão ativa (#326).
class CompetitionDetailScreen extends ConsumerStatefulWidget {
  const CompetitionDetailScreen({
    super.key,
    this.competitionId,
    this.competition,
  });

  final String? competitionId;
  final Competition? competition;

  @override
  ConsumerState<CompetitionDetailScreen> createState() =>
      _CompetitionDetailScreenState();
}

class _CompetitionDetailScreenState
    extends ConsumerState<CompetitionDetailScreen> {
  static const _sessions = [
    'Campeonato',
    'Modalidade',
    'Categoria',
    'Temporada',
    'Conferências',
    'Agrupamento',
    'Clubes',
  ];

  /// Ícones das sessões (issue #326), paralelos a [_sessions].
  static const _sessionIcons = <IconData>[
    Icons.emoji_events_outlined,
    Icons.sports_football_outlined,
    Icons.groups_outlined,
    Icons.date_range,
    Icons.account_tree_outlined,
    Icons.hub_outlined,
    Icons.groups,
  ];

  /// Índice da sessão ativa — único bloco exibido no corpo da tela (#326).
  int _activeSession = 0;

  @override
  Widget build(BuildContext context) {
    final compFuture = widget.competition != null
        ? null
        : ref.watch(competitionProvider(widget.competitionId!));

    return AppScreen(
      title: widget.competition?.name ?? 'Campeonato',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: AppLayout.form(
              child: AppStepIndicator(
                titles: _sessions,
                icons: _sessionIcons,
                currentStep: _activeSession,
                showDoneState: false,
                onStepTap: (index) => setState(() => _activeSession = index),
              ),
            ),
          ),
          Expanded(
            child: compFuture == null
                ? _buildDetail(context, widget.competition!)
                : compFuture.when(
                    loading: () =>
                        const AppLoading(message: 'Carregando campeonato...'),
                    error: (error, stackTrace) => AppErrorState(
                      message: 'Não foi possível carregar o campeonato',
                      onRetry: () => ref.invalidate(
                        competitionProvider(widget.competitionId!),
                      ),
                    ),
                    data: (comp) => _buildDetail(context, comp),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Competition comp) {
    // Issue #261: edição exige ser criador do campeonato ou ADMIN.
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider).state.user,
      comp,
    );
    final isDraft = comp.status == CompetitionStatus.draft;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppLayout.detail(
        child: switch (_activeSession) {
          0 => _campeonatoCard(context, comp, canEdit, isDraft),
          1 =>
            comp.modality == null
                ? const SizedBox.shrink()
                : _modalidadeCard(comp),
          2 =>
            (comp.gender == null && comp.ageGroup == null)
                ? const SizedBox.shrink()
                : _categoriaCard(comp),
          3 =>
            (comp.startDate == null && comp.endDate == null)
                ? const SizedBox.shrink()
                : _temporadaCard(comp),
          4 => _conferencesCard(comp),
          5 => _estruturaCard(context, comp, canEdit, isDraft),
          _ => _clubsCard(context, comp, canEdit, isDraft),
        },
      ),
    );
  }

  /// Sessão 1 — Campeonato (#306): identidade + ações por status,
  /// espelhando a primeira sessão do wizard de cadastro.
  Widget _campeonatoCard(
    BuildContext context,
    Competition comp,
    bool canEdit,
    bool isDraft,
  ) {
    return Card(
      child: Container(
        constraints: const BoxConstraints(minHeight: 160),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Campeonato', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.emoji_events_outlined,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comp.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comp.organizationName ??
                            (comp.organizationId != null
                                ? 'Organização #${comp.organizationId}'
                                : ''),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _statusChip(comp.status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // V250: edição permitida apenas enquanto rascunho.
            // Issue #261: e apenas pelo criador ou ADMIN.
            if (isDraft && canEdit)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.go(
                      '/competitions/${comp.id}/edit',
                      extra: comp,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar campeonato'),
                  ),
                  // Issue #381: novo ponto de entrada para rodadas/confrontos,
                  // ao lado de "Editar campeonato" (recupera o acesso a /rounds).
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(selectedCompetitionProvider.notifier).state =
                          comp.id;
                      context.go('/rounds');
                    },
                    icon: const Icon(Icons.format_list_numbered),
                    label: const Text('Rodadas'),
                  ),
                ],
              )
            else
              Text(
                isDraft
                    ? 'Apenas o criador do campeonato pode editá-lo.'
                    : 'Campeonato publicado — não é mais editável.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            // Descrição pertence à sessão Campeonato (wizard).
            if (comp.description != null && comp.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              AppInfoRow(label: 'Descrição', value: comp.description!),
            ],
          ],
        ),
      ),
    );
  }

  /// Sessão 2 — Modalidade (#306).
  Widget _modalidadeCard(Competition comp) {
    return AppInfoCard(
      title: 'Modalidade',
      children: [
        AppInfoRow(
          label: 'Modalidade',
          value: comp.modality?.label ?? 'Não definido',
        ),
      ],
    );
  }

  /// Sessão 3 — Categoria (#306): gênero + faixa etária.
  Widget _categoriaCard(Competition comp) {
    return AppInfoCard(
      title: 'Categoria',
      children: [
        AppInfoRow(label: 'Gênero', value: _genderLabel(comp.gender)),
        AppInfoRow(label: 'Faixa etária', value: _ageGroupLabel(comp.ageGroup)),
      ],
    );
  }

  /// Sessão 4 — Temporada (#306).
  Widget _temporadaCard(Competition comp) {
    return AppInfoCard(
      title: 'Temporada',
      children: [
        if (comp.startDate != null)
          AppInfoRow(label: 'Início', value: _formatDate(comp.startDate!)),
        if (comp.endDate != null)
          AppInfoRow(label: 'Fim', value: _formatDate(comp.endDate!)),
        if (comp.startDate == null && comp.endDate == null)
          AppInfoRow(label: 'Período', value: 'Não definido'),
      ],
    );
  }

  /// Sessão 6 — Agrupamento (#306/#349): reflete apenas o que foi cadastrado
  /// (divisões/grupos), sem a linha "Modelo" nem botões de ação.
  /// Oculto quando o campeonato não tem divisões.
  Widget _estruturaCard(
    BuildContext context,
    Competition comp,
    bool canEdit,
    bool isDraft,
  ) {
    final divisions = ref.watch(divisionsProvider(comp.id));
    final conferences =
        ref.watch(conferencesProvider(comp.id)).valueOrNull ??
        const <Conference>[];
    return divisions.when(
      loading: () => AppInfoCard(
        title: 'Agrupamento',
        children: const [
          Text(
            'Carregando agrupamento...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
      error: (e, s) => AppInfoCard(
        title: 'Agrupamento',
        children: const [
          Text(
            'Não foi possível carregar as divisões.',
            style: TextStyle(color: AppColors.danger, fontSize: 13),
          ),
        ],
      ),
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : AppInfoCard(
              title: 'Agrupamento',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final division in items)
                      _divisionChip(
                        division.name,
                        conferenceName: division.conferenceId == null
                            ? null
                            : conferences
                                  .where((c) => c.id == division.conferenceId)
                                  .map((c) => c.name)
                                  .firstOrNull,
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  /// Sessão 7 — Clubes (#377): lista simples dos clubes (organizações)
  /// associados ao campeonato + botão para a tela de associação.
  Widget _clubsCard(
    BuildContext context,
    Competition comp,
    bool canEdit,
    bool isDraft,
  ) {
    final teams = ref.watch(teamsProvider(comp.id));
    final organizations = ref.watch(organizationsProvider);

    return teams.when(
      loading: () => AppInfoCard(
        title: 'Clubes',
        children: const [
          Text(
            'Carregando clubes...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
      error: (e, s) => AppInfoCard(
        title: 'Clubes',
        children: const [
          Text(
            'Não foi possível carregar os clubes.',
            style: TextStyle(color: AppColors.danger, fontSize: 13),
          ),
        ],
      ),
      data: (items) {
        final orgs = organizations.valueOrNull ?? const <Organization>[];
        final orgById = {for (final o in orgs) o.id: o};
        final clubs = items
            .map((t) => orgById[t.organizationId ?? ''])
            .whereType<Organization>()
            .toList();

        return AppInfoCard(
          title: 'Clubes',
          children: [
            if (clubs.isEmpty)
              const Text(
                'Nenhum clube associado.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final club in clubs)
                    _clubChip(
                      club.tradeName,
                      subtitle: club.city?.isNotEmpty == true ? club.city : null,
                    ),
                ],
              ),
            const SizedBox(height: 12),
            if (canEdit && isDraft)
              FilledButton.icon(
                onPressed: () {
                  ref.read(selectedCompetitionProvider.notifier).state =
                      comp.id;
                  context.go('/teams/associate', extra: comp.id);
                },
                icon: const Icon(Icons.groups),
                label: const Text('Associar clubes'),
              )
            else
              const Text(
                'Apenas o criador do campeonato pode associar clubes.',
                style:
                    TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
          ],
        );
      },
    );
  }

  Widget _clubChip(String name, {String? subtitle}) {
    final label = subtitle == null ? name : '$name · $subtitle';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grayFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.groups,
            size: 14,
            color: AppColors.textSecondary,
          ),
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

  /// Sessão Conferências (#323/#345): lista as conferências do campeonato.
  /// Oculto quando não há conferências (#345).
  Widget _conferencesCard(Competition comp) {
    final conferences = ref.watch(conferencesProvider(comp.id));
    return conferences.when(
      loading: () => AppInfoCard(
        title: 'Conferências',
        children: const [
          Text(
            'Carregando conferências...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
      error: (e, s) => AppInfoCard(
        title: 'Conferências',
        children: const [
          Text(
            'Não foi possível carregar as conferências.',
            style: TextStyle(color: AppColors.danger, fontSize: 13),
          ),
        ],
      ),
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : AppInfoCard(
              title: 'Conferências',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final c in items) _conferenceChip(c.name)],
                ),
              ],
            ),
    );
  }

  Widget _conferenceChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grayFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_tree_outlined,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _divisionChip(String name, {String? conferenceName}) {
    final label = conferenceName == null ? name : '$name · $conferenceName';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grayFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.folder_outlined,
            size: 14,
            color: AppColors.textSecondary,
          ),
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

  String _genderLabel(String? gender) => switch (gender) {
    'MALE' => 'Masculino',
    'FEMALE' => 'Feminino',
    'MIXED' => 'Misto',
    _ => 'Não definido',
  };

  String _ageGroupLabel(String? ageGroup) => switch (ageGroup) {
    'SUB11' => 'Sub-11',
    'SUB13' => 'Sub-13',
    'SUB14' => 'Sub-14',
    'SUB15' => 'Sub-15',
    'SUB17' => 'Sub-17',
    'SUB20' => 'Sub-20',
    'ADULT' => 'Adulto',
    'MASTER' => 'Master',
    'OPEN' => 'Livre',
    _ => 'Não definido',
  };

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
