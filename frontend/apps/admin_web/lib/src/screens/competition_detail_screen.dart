import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../widgets/app_back_button.dart';

/// Detalhe de um campeonato: apresenta os dados e oferece a ediÃ§Ã£o.
///
/// A navegaÃ§Ã£o para esta tela NÃƒO abre o formulÃ¡rio de ediÃ§Ã£o diretamente;
/// a ediÃ§Ã£o Ã© uma aÃ§Ã£o explÃ­cita na tela.
class CompetitionDetailScreen extends ConsumerWidget {
  const CompetitionDetailScreen({
    super.key,
    this.competitionId,
    this.competition,
  });

  final String? competitionId;
  final Competition? competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compFuture = competition != null
        ? null
        : ref.watch(competitionProvider(competitionId!));

    return Scaffold(
      appBar: AppBar(
        title: Text(competition?.name ?? 'Campeonato'),
        leading: AppBackButton(fallbackRoute: '/competitions'),
      ),
      body: compFuture == null
          ? _buildDetail(context, ref, competition!)
          : compFuture.when(
              loading: () =>
                  const AppLoading(message: 'Carregando campeonato...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'NÃ£o foi possÃ­vel carregar o campeonato',
                onRetry: () =>
                    ref.invalidate(competitionProvider(competitionId!)),
              ),
              data: (comp) => _buildDetail(context, ref, comp),
            ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Competition comp) {
    // Issue #261: edição exige ser criador do campeonato ou ADMIN.
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider).state.user,
      comp,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppLayout.detail(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Identidade: cabeÃ§alho do campeonato com ediÃ§Ã£o explÃ­cita.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                        ? 'OrganizaÃ§Ã£o #${comp.organizationId}'
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
                    // Issue #261: e apenas pelo criador do campeonato ou ADMIN.
                    if (comp.status == CompetitionStatus.draft && canEdit)
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
                        comp.status == CompetitionStatus.draft
                            ? 'Apenas o criador do campeonato pode editá-lo.'
                            : 'Campeonato publicado — não é mais editável.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    // Issue #259: atalho para gerenciar rodadas já no
                    // contexto deste campeonato. Segue a mesma regra de
                    // permissão da edição (criador ou ADMIN), sem restrição
                    // de status — rodadas também são geridas após publicar.
                    if (canEdit) ...[
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Atributos da competiÃ§Ã£o.
            _infoCard('Atributos', [
              _row('Modalidade', comp.modality?.label ?? 'NÃ£o definido'),
              _row('GÃªnero', _genderLabel(comp.gender)),
              _row('Faixa EtÃ¡ria', _ageGroupLabel(comp.ageGroup)),
            ]),
            const SizedBox(height: 12),

            // PerÃ­odo de realizaÃ§Ã£o.
            _infoCard('PerÃ­odo', [
              if (comp.startDate != null)
                _row('InÃ­cio', _formatDate(comp.startDate!)),
              if (comp.endDate != null) _row('Fim', _formatDate(comp.endDate!)),
              if (comp.startDate == null && comp.endDate == null)
                _row('PerÃ­odo', 'NÃ£o definido'),
            ]),
            const SizedBox(height: 12),

            // DescriÃ§Ã£o opcional.
            if (comp.description != null && comp.description!.isNotEmpty) ...[
              _infoCard('DescriÃ§Ã£o', [
                _row('DescriÃ§Ã£o', comp.description!),
              ]),
              const SizedBox(height: 12),
            ],

            // AÃ§Ãµes dentro do campeonato.
            _infoCard('AÃ§Ãµes do campeonato', [
              _actionRowButton(
                context,
                icon: Icons.account_tree_outlined,
                label: 'Gerenciar ConferÃªncias e DivisÃµes',
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
            ]),
          ],
        ),
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
    _ => 'NÃ£o definido',
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
    _ => 'NÃ£o definido',
  };

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
