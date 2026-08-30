import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../utils/date_formats.dart';
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
      breadcrumb: [
        const BreadcrumbItem('Início', route: '/'),
        const BreadcrumbItem(AppStrings.athletes, route: '/athletes'),
        if (athlete?.name != null) BreadcrumbItem(athlete!.name),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conteúdo
          athleteFuture == null
              ? _buildDetail(context, athlete!)
              : athleteFuture.when(
                  loading: () =>
                      const AppLoading(message: 'Carregando atleta...'),
                  error: (error, stackTrace) => AppErrorState(
                    message: 'Não foi possível carregar o atleta',
                    onRetry: () =>
                        ref.invalidate(athleteProvider(athleteId!)),
                  ),
                  data: (athlete) => _buildDetail(context, athlete),
                ),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Athlete athlete) {
    return AppLayout.detail(
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
                        KicksterAvatar(
                          name: athlete.name,
                          imageUrl: athlete.photoUrl,
                          size: 64,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                athlete.name,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w700),
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
                    KicksterButton(
                      label: 'Editar dados',
                      icon: Icons.edit_outlined,
                      onPressed: () => context.go(
                        '/athletes/${athlete.id}/edit',
                        extra: athlete,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppInfoCard(children: [
              AppInfoRow(label: 'Nome', value: athlete.name),
              AppInfoRow(
                label: 'Apelido',
                value: athlete.nickname?.isNotEmpty == true
                    ? athlete.nickname!
                    : '—',
              ),
              AppInfoRow(
                label: 'Posição',
                value: athlete.positionsLabel.isNotEmpty
                    ? athlete.positionsLabel
                    : 'Sem posição',
              ),
              AppInfoRow(
                label: 'Número da camisa',
                value: athlete.number?.toString() ?? '—',
              ),
              if (athlete.photoUrl != null && athlete.photoUrl!.isNotEmpty)
                AppInfoRow(label: 'URL da foto', value: athlete.photoUrl!),
            ]),
            const SizedBox(height: 16),
            Text(
              'Criado em ${formatBrDate(athlete.createdAt)}'
              '${athlete.updatedAt != null ? ' • Atualizado em ${formatBrDate(athlete.updatedAt)}' : ''}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
    );
  }
}
