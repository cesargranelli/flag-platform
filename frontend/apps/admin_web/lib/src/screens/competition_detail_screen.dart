import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_back_button.dart';

/// Detalhe de um campeonato: apresenta os dados e oferece a edição.
///
/// A navegação para esta tela NÃO abre o formulário de edição diretamente;
/// a edição é uma ação explícita na tela.
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
                message: 'Não foi possível carregar o campeonato',
                onRetry: () =>
                    ref.invalidate(competitionProvider(competitionId!)),
              ),
              data: (comp) => _buildDetail(context, ref, comp),
            ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Competition comp) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppLayout.detail(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                                        ? 'Organização #${comp.organizationId}'
                                        : ''),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(children: [_statusChip(comp.status)]),
                    const SizedBox(height: 16),
                    _infoCard('Atributos', [
                      _row(
                        'Modalidade',
                        comp.modalityId != null ? 'Definido' : 'Não definido',
                      ),
                      _row('Gênero', comp.gender ?? 'Não definido'),
                      _row('Faixa Etária', comp.ageGroup ?? 'Não definido'),
                    ]),
                    const SizedBox(height: 16),
                    _infoCard('Ações dentro do campeonato', [
                      _actionRowButton(
                        context,
                        icon: Icons.account_tree_outlined,
                        label: 'Gerenciar Conferências e Divisões',
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
                    const SizedBox(height: 12),
                    _infoCard('Informações', [
                      _row('Nome', comp.name),
                      _row('Status', _statusLabel(comp.status)),
                      if (comp.organizationName != null)
                        _row('Organização', comp.organizationName!),
                      if (comp.description != null &&
                          comp.description!.isNotEmpty)
                        _row('Descrição', comp.description!),
                    ]),
                    const SizedBox(height: 12),
                    _infoCard('Período', [
                      if (comp.startDate != null)
                        _row('Início', _formatDate(comp.startDate!)),
                      if (comp.endDate != null)
                        _row('Fim', _formatDate(comp.endDate!)),
                      if (comp.startDate == null && comp.endDate == null)
                        _row('Período', 'Não definido'),
                    ]),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
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
  };

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
