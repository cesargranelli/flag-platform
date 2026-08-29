import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Detalhe de um atleta: apresenta os dados e oferece a edição.
///
/// O atleta não possui exclusão (backend sem DELETE). A edição é uma ação
/// explícita na tela.
class AthleteDetailScreen extends ConsumerWidget {
  const AthleteDetailScreen({super.key, this.athleteId, this.athlete});

  final String? athleteId;
  final Athlete? athlete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final athleteFuture = athlete != null
        ? null
        : ref.watch(athleteProvider(athleteId!));

    return AppScreen(
      title: athlete?.name ?? 'Atleta',
      body: athleteFuture == null
          ? _buildDetail(context, athlete!)
          : athleteFuture.when(
              loading: () => const AppLoading(message: 'Carregando atleta...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar o atleta',
                onRetry: () => ref.invalidate(athleteProvider(athleteId!)),
              ),
              data: (athlete) => _buildDetail(context, athlete),
            ),
    );
  }

  Widget _buildDetail(BuildContext context, Athlete athlete) {
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
                        _avatar(athlete, size: 64, radius: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                athlete.name,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              if (athlete.nickname != null &&
                                  athlete.nickname!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  athlete.nickname!,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.go(
                        '/athletes/${athlete.id}/edit',
                        extra: athlete,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar dados'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _infoCard([
              _row('Nome', athlete.name),
              _row('Apelido', athlete.nickname?.isNotEmpty == true ? athlete.nickname! : '—'),
              _row('Posição', athlete.positionsLabel.isNotEmpty ? athlete.positionsLabel : 'Sem posição'),
              _row('Número da camisa', athlete.number?.toString() ?? '—'),
              if (athlete.photoUrl != null && athlete.photoUrl!.isNotEmpty)
                _row('URL da foto', athlete.photoUrl!),
            ]),
            const SizedBox(height: 16),
            Text(
              'Criado em ${_formatDate(athlete.createdAt)}'
              '${athlete.updatedAt != null ? ' • Atualizado em ${_formatDate(athlete.updatedAt)}' : ''}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(Athlete athlete, {required double size, required double radius}) {
    final photo = athlete.photoUrl;
    final validPhoto = photo != null &&
        photo.isNotEmpty &&
        (Uri.tryParse(photo)?.hasScheme ?? false);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: validPhoto
          ? Image.network(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  _initials(athlete.name),
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: size * 0.4),
                ),
              ),
            )
          : Center(
              child: Text(
                _initials(athlete.name),
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: size * 0.4),
              ),
            ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Widget _infoCard(List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
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
            width: 130,
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
