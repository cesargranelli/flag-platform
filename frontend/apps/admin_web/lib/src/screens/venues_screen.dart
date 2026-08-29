import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Gestão de campos de jogo: cards e navegação para o detalhe.
///
/// Listagem em grid de cards (padrão web); clicar navega para a tela de
/// detalhe do campo.
class VenuesScreen extends ConsumerWidget {
  const VenuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venues = ref.watch(venuesProvider);
    final organizations = ref.watch(organizationsProvider);

    return AppScreen(
      title: 'Campos',
      actions: [
        FilledButton.icon(
          onPressed: () => context.go('/venues/new'),
          icon: const Icon(Icons.add),
          label: const Text('Novo'),
        ),
      ],
      body: venues.when(
        loading: () => const AppLoading(message: 'Carregando campos...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar os campos',
          onRetry: () => ref.invalidate(venuesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhum campo cadastrado',
              icon: Icons.sports_soccer,
            );
          }
          final orgNames = organizations.valueOrNull ?? const <Organization>[];
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
                    final venue = items[index];
                    return _venueCard(
                      context,
                      venue,
                      orgNames,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Card de campo no padrão Kickster (core #439): ícone de futebol, nome
  /// e subtítulo com organização + endereço.
  Widget _venueCard(
    BuildContext context,
    Venue venue,
    List<Organization> organizations,
  ) {
    final orgName = _organizationName(venue.organizationId, organizations);
    final subtitle = [
      if (orgName.isNotEmpty) orgName,
      if (venue.address != null && venue.address!.isNotEmpty) venue.address!,
    ].join(' • ');

    return KicksterCard(
      icon: Icons.sports_soccer,
      title: venue.name,
      subtitle: subtitle.isEmpty ? null : subtitle,
      onTap: () => context.go('/venues/${venue.id}', extra: venue),
    );
  }

  String _organizationName(String id, List<Organization> organizations) {
    final match = organizations.where((o) => o.id == id).toList();
    return match.isEmpty ? '' : match.first.tradeName;
  }
}
