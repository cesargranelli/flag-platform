import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Gestão de atletas: cards e navegação para o detalhe.
class AthletesScreen extends ConsumerWidget {
  const AthletesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final athletes = ref.watch(athletesProvider);

    return AppScreen(
      title: 'Atletas',
      titleVariant: AppScreenTitleVariant.titleLg,
      actions: [
        IconButton(
          tooltip: 'Importar CSV',
          icon: const Icon(Icons.upload_file),
          onPressed: () => context.push('/athletes/import'),
        ),
        FilledButton.icon(
          onPressed: () => context.go('/athletes/new'),
          icon: const Icon(Icons.add),
          label: const Text('Novo'),
        ),
      ],
      body: athletes.when(
        loading: () => const AppLoading(message: 'Carregando atletas...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar os atletas',
          onRetry: () => ref.invalidate(athletesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhum atleta cadastrado',
              icon: Icons.person_outline,
            );
          }
          return AppLayout.content(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 600 ? 2 : 1;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 96,
                  ),
                  itemBuilder: (context, index) {
                    final athlete = items[index];
                    return _athleteCard(context, athlete);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Card de atleta no padrão Kickster (core #439): ícone de pessoa, nome e
  /// subtítulo com número + posições.
  Widget _athleteCard(BuildContext context, Athlete athlete) {
    final positions = athlete.positionsLabel;
    final subtitle = [
      if (athlete.number != null) '#${athlete.number}',
      if (positions.isNotEmpty) positions,
    ].join(' · ');

    return KicksterCard(
      icon: Icons.person_outline,
      title: athlete.name,
      subtitle: subtitle.isEmpty ? null : subtitle,
      onTap: () => context.go('/athletes/${athlete.id}', extra: athlete),
    );
  }
}
