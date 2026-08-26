import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_screen.dart';

/// Detalhe de um campeonato em sessões espelhando o wizard (#306),
/// com navegação fluida por chips no topo (#316): tocar em uma sessão
/// rola suavemente até o respectivo card, e o chip da seção visível
/// fica destacado conforme a rolagem.
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
    'Estrutura',
  ];

  /// Limiar (px do topo do card) que considera a sessão como ativa na rolagem.
  static const _activeSessionTopLimit = 180.0;

  final _scrollController = ScrollController();
  final _sessionKeys = List<GlobalKey>.generate(
    _sessions.length,
    (_) => GlobalKey(),
  );
  int _activeSession = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateActiveSession);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateActiveSession);
    _scrollController.dispose();
    super.dispose();
  }

  /// Destaca o chip da sessão cujo card está no topo da viewport.
  void _updateActiveSession() {
    var active = 0;
    for (var i = 0; i < _sessionKeys.length; i++) {
      final ctx = _sessionKeys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject();
      if (box is! RenderBox) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      if (top <= _activeSessionTopLimit) active = i;
    }
    if (active != _activeSession && mounted) {
      setState(() => _activeSession = active);
    }
  }

  void _scrollToSession(int index) {
    final ctx = _sessionKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.0,
    );
    setState(() => _activeSession = index);
  }

  @override
  Widget build(BuildContext context) {
    final compFuture = widget.competition != null
        ? null
        : ref.watch(competitionProvider(widget.competitionId!));

    return AppScreen(
      title: widget.competition?.name ?? 'Campeonato',
      leading: AppBackButton(fallbackRoute: '/competitions'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: AppSessionNav(
              sessions: _sessions,
              activeIndex: _activeSession,
              onTap: _scrollToSession,
            ),
          ),
          Expanded(
            child: compFuture == null
                ? _buildDetail(context, ref, widget.competition!)
                : compFuture.when(
                    loading: () => const AppLoading(
                      message: 'Carregando campeonato...',
                    ),
                    error: (error, stackTrace) => AppErrorState(
                      message: 'Não foi possível carregar o campeonato',
                      onRetry: () => ref.invalidate(
                        competitionProvider(widget.competitionId!),
                      ),
                    ),
                    data: (comp) => _buildDetail(context, ref, comp),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Competition comp) {
    // Issue #261: edição exige ser criador do campeonato ou ADMIN.
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider).state.user,
      comp,
    );
    final isDraft = comp.status == CompetitionStatus.draft;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: AppLayout.detail(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sessão 1 — Campeonato (#306): identidade + ações por status,
            // espelhando a primeira sessão do wizard de cadastro.
            KeyedSubtree(
              key: _sessionKeys[0],
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campeonato',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.12),
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
                        FilledButton.icon(
                          onPressed: () => context.push(
                            '/competitions/${comp.id}/edit',
                            extra: comp,
                          ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar campeonato'),
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
                      // Issue #259/#305: rodadas apenas em DRAFT.
                      if (canEdit && isDraft) ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () {
                            ref
                                    .read(selectedCompetitionProvider.notifier)
                                    .state =
                                comp.id;
                            context.push('/rounds');
                          },
                          icon: const Icon(Icons.format_list_numbered),
                          label: const Text('Adicionar rodadas'),
                        ),
                      ],
                      // Descrição pertence à sessão Campeonato (wizard).
                      if (comp.description != null &&
                          comp.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _row('Descrição', comp.description!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Sessão 2 — Modalidade (#306).
            KeyedSubtree(
              key: _sessionKeys[1],
              child: _infoCard('Modalidade', [
                _row('Modalidade', comp.modality?.label ?? 'Não definido'),
              ]),
            ),
            const SizedBox(height: 12),

            // Sessão 3 — Categoria (#306): gênero + faixa etária.
            KeyedSubtree(
              key: _sessionKeys[2],
              child: _infoCard('Categoria', [
                _row('Gênero', _genderLabel(comp.gender)),
                _row('Faixa etária', _ageGroupLabel(comp.ageGroup)),
              ]),
            ),
            const SizedBox(height: 12),

            // Sessão 4 — Temporada (#306).
            KeyedSubtree(
              key: _sessionKeys[3],
              child: _infoCard('Temporada', [
                if (comp.startDate != null)
                  _row('Início', _formatDate(comp.startDate!)),
                if (comp.endDate != null)
                  _row('Fim', _formatDate(comp.endDate!)),
                if (comp.startDate == null && comp.endDate == null)
                  _row('Período', 'Não definido'),
              ]),
            ),
            const SizedBox(height: 12),

            // Sessão 5 — Conferências (#323): presentes no cadastro (estrutura).
            KeyedSubtree(
              key: _sessionKeys[4],
              child: _conferencesCard(comp),
            ),
            const SizedBox(height: 12),

            // Sessão 6 — Estrutura (#306): agrupamentos dos clubes.
            // Issue #305: ações de escrita apenas em DRAFT.
            KeyedSubtree(
              key: _sessionKeys[5],
              child: _infoCard('Estrutura', [
                _row(
                  'Modelo',
                  comp.groupingType?.label ??
                      GroupingType.divisions.label,
                ),
                if (canEdit && isDraft) ...[
                  _actionRowButton(
                    context,
                    icon: Icons.account_tree_outlined,
                    label: comp.groupingType == GroupingType.groups
                        ? 'Gerenciar Conferências e Grupos'
                        : 'Gerenciar Conferências e Divisões',
                    onTap: () {
                      ref.read(selectedCompetitionProvider.notifier).state =
                          comp.id;
                      context.push('/groupings');
                    },
                  ),
                  _actionRowButton(
                    context,
                    icon: Icons.groups,
                    label: 'Associar Clubes',
                    onTap: () {
                      ref.read(selectedCompetitionProvider.notifier).state =
                          comp.id;
                      context.push('/teams');
                    },
                  ),
                ] else ...[
                  Text(
                    'Campeonato publicado — a estrutura está travada.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }

  /// Sessão Conferências (#323): lista as conferências do campeonato.
  Widget _conferencesCard(Competition comp) {
    final conferences = ref.watch(conferencesProvider(comp.id));
    return _infoCard(
      'Conferências',
      conferences.when(
        loading: () => const [
          Text(
            'Carregando conferências...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
        error: (e, s) => const [
          Text(
            'Não foi possível carregar as conferências.',
            style: TextStyle(color: AppColors.danger, fontSize: 13),
          ),
        ],
        data: (items) => items.isEmpty
            ? const [
                Text(
                  'Sem conferências definidas.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ]
            : [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in items) _conferenceChip(c.name),
                  ],
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
          Text(name, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _actionRowButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextButton(
              onPressed: onTap,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
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
