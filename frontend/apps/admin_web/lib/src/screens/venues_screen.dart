import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_entity_list_screen.dart';
import '../widgets/app_screen.dart';

/// Gestão de campos de jogo: cards e navegação para o detalhe.
///
/// Listagem em grid de cards (padrão web) com busca por nome; clicar navega
/// para a tela de detalhe do campo.
class VenuesScreen extends ConsumerStatefulWidget {
  const VenuesScreen({super.key});

  @override
  ConsumerState<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends ConsumerState<VenuesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final venues = ref.watch(venuesProvider);
    final organizations = ref.watch(organizationsProvider);

    return AppScreen(
      title: 'Campos',
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem('Campos'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Actions
          Row(
            children: [
              const Spacer(),
              KicksterButton(
                label: 'Novo',
                icon: Icons.add,
                onPressed: () => context.go('/venues/new'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Conteúdo (Expanded para dar altura finita ao grid)
          Expanded(
            child: venues.when(
              loading: () =>
                  const AppLoading(message: 'Carregando campos...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar os campos',
                onRetry: () => ref.invalidate(venuesProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return KicksterEmptyState(
                    icon: Icons.sports_soccer,
                    message: 'Nenhum campo cadastrado',
                    description:
                        'Crie o primeiro campo para começar a usar.',
                    action: KicksterButton(
                      label: 'Criar campo',
                      icon: Icons.add,
                      onPressed: () => context.go('/venues/new'),
                    ),
                  );
                }
                final orgNames = organizations.valueOrNull ??
                    const <Organization>[];
                // Pré-computa o mapa orgId → nome UMA vez (lookup O(1) no card)
                // em vez de percorrer a lista de organizações por card (O(n²)).
                final orgNameById = <String, String>{
                  for (final o in orgNames) o.id: o.tradeName,
                };
                return AppEntityListScreen<Venue>(
                  items: items,
                  cardBuilder: (venue) =>
                      _venueCard(context, venue, orgNameById),
                  searchField: _searchController,
                  countLabel: 'campos',
                  countLabelSingular: 'campo',
                  emptyMessage: 'Nenhum campo encontrado',
                  filter: (all, query) => query.isEmpty
                      ? all
                      : all
                          .where(
                              (v) => v.name.toLowerCase().contains(query))
                          .toList(growable: false),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Card de campo no padrão Kickster (core #439): ícone de futebol, nome
  /// e subtítulo com organização + endereço.
  Widget _venueCard(
    BuildContext context,
    Venue venue,
    Map<String, String> orgNameById,
  ) {
    final orgName = orgNameById[venue.organizationId] ?? '';
    final subtitle = [
      if (orgName.isNotEmpty) orgName,
      if (venue.address != null && venue.address!.isNotEmpty) venue.address!,
    ].join(' • ');

    return KicksterCard(
      icon: Icons.sports_soccer,
      title: venue.name,
      subtitle: subtitle.isEmpty ? null : subtitle,
      onTap: () => context.push('/venues/${venue.id}', extra: venue),
    );
  }
}
