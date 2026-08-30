import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_entity_list_screen.dart';
import '../widgets/app_screen.dart';

/// Gestão de atletas: cards e navegação para o detalhe.
class AthletesScreen extends ConsumerStatefulWidget {
  const AthletesScreen({super.key});

  @override
  ConsumerState<AthletesScreen> createState() => _AthletesScreenState();
}

class _AthletesScreenState extends ConsumerState<AthletesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final athletes = ref.watch(athletesProvider);

    return AppScreen(
      title: 'Atletas',
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem('Atletas'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Actions
          Row(
            children: [
              const Spacer(),
              KicksterButton(
                label: 'Importar',
                icon: Icons.upload_file,
                variant: KicksterButtonVariant.outline,
                onPressed: () => context.push('/athletes/import'),
              ),
              const SizedBox(width: 8),
              KicksterButton(
                label: 'Novo',
                icon: Icons.add,
                onPressed: () => context.go('/athletes/new'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Conteúdo (Expanded para dar altura finita ao grid)
          Expanded(
            child: athletes.when(
              loading: () => const AppLoading(message: 'Carregando atletas...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar os atletas',
                onRetry: () => ref.invalidate(athletesProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return KicksterEmptyState(
                    icon: Icons.person_outline,
                    message: 'Nenhum atleta cadastrado',
                    description: 'Crie o primeiro atleta para começar a usar.',
                    action: KicksterButton(
                      label: 'Criar atleta',
                      icon: Icons.add,
                      onPressed: () => context.go('/athletes/new'),
                    ),
                  );
                }
                return AppEntityListScreen<Athlete>(
                  items: items,
                  cardBuilder: (athlete) => _athleteCard(context, athlete),
                  searchField: _searchController,
                  countLabel: 'atletas',
                  countLabelSingular: 'atleta',
                  emptyMessage: 'Nenhum atleta encontrado',
                  filter: (all, query) => query.isEmpty
                      ? all
                      : all
                          .where(
                              (a) => a.name.toLowerCase().contains(query))
                          .toList(growable: false),
                );
              },
            ),
          ),
        ],
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
      onTap: () => context.push('/athletes/${athlete.id}', extra: athlete),
    );
  }
}
