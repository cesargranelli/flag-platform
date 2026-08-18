import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_back_button.dart';

/// Detalhe de uma rodada: apresenta os dados e oferece a edição.
///
/// A rodada não possui exclusão (backend sem DELETE). A edição é uma ação
/// explícita na tela.
class RoundDetailScreen extends ConsumerWidget {
  const RoundDetailScreen({super.key, this.roundId, this.round});

  final String? roundId;
  final Round? round;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roundFuture = round != null ? null : ref.watch(roundProvider(roundId!));

    return Scaffold(
      appBar: AppBar(
        title: Text(round?.name ?? 'Rodada'),
        leading: AppBackButton(fallbackRoute: '/rounds'),
      ),
      body: roundFuture == null
          ? _buildDetail(context, ref, round!)
          : roundFuture.when(
              loading: () => const AppLoading(message: 'Carregando rodada...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar a rodada',
                onRetry: () => ref.invalidate(roundProvider(roundId!)),
              ),
              data: (round) => _buildDetail(context, ref, round),
            ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Round round) {
    final category = ref.watch(categoryProvider(round.categoryId)).valueOrNull;
    final competitions = ref.watch(competitionsProvider);
    final competitionName = competitions.valueOrNull
            ?.where((c) => c.id == category?.competitionId)
            .map((c) => c.name)
            .firstOrNull ??
        '';

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
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              '${round.number}',
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                round.name,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                round.type.label,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.push(
                        '/rounds/${round.id}/edit',
                        extra: round,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar dados'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _infoCard(
              'Informações',
              [
                _row('Número', '${round.number}'),
                _row('Nome', round.name),
                _row('Tipo', round.type.label),
                _row('Categoria', category?.name ?? '—'),
                _row('Campeonato', competitionName),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Criado em ${_formatDate(round.createdAt)}'
              '${round.updatedAt != null ? ' • Atualizado em ${_formatDate(round.updatedAt)}' : ''}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
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
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
