import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Gestão de atletas: cards e navegação para o detalhe.
class AthletesScreen extends ConsumerStatefulWidget {
  const AthletesScreen({super.key});

  @override
  ConsumerState<AthletesScreen> createState() => _AthletesScreenState();
}

class _AthletesScreenState extends ConsumerState<AthletesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título + actions
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Atletas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
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
          // Conteúdo
          athletes.when(
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
              final query = _query.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? items
                  : items
                      .where((a) => a.name.toLowerCase().contains(query))
                      .toList(growable: false);

              return Column(
                children: [
                  Row(
                    children: [
                      if (query.isNotEmpty)
                        Text(
                          '${filtered.length} ${filtered.length == 1 ? 'resultado' : 'resultados'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        Text(
                          '${items.length} ${items.length == 1 ? 'atleta' : 'atletas'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const Spacer(),
                      SizedBox(
                        width: 280,
                        child: KicksterSearchField(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => _query = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    const AppEmptyState(
                      message: 'Nenhum atleta encontrado',
                      icon: Icons.search_off,
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns =
                            constraints.maxWidth >= 600 ? 2 : 1;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 96,
                          ),
                          itemBuilder: (context, index) {
                            final athlete = filtered[index];
                            return _athleteCard(context, athlete);
                          },
                        );
                      },
                    ),
                ],
              );
            },
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
