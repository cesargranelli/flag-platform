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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/venues/${venue.id}', extra: venue),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sports_soccer,
                    color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      venue.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _organizationName(String id, List<Organization> organizations) {
    final match = organizations.where((o) => o.id == id).toList();
    return match.isEmpty ? '' : match.first.tradeName;
  }
}
