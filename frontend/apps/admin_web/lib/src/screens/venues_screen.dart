import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Gestão de campos de jogo: lista e acesso ao formulário.
class VenuesScreen extends ConsumerWidget {
  const VenuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venues = ref.watch(venuesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campos'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo campo',
        onPressed: () => context.push('/venues/new'),
        child: const Icon(Icons.add),
      ),
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
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final venue = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(venue.name),
                  subtitle: Text(venue.address ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push('/venues/${venue.id}', extra: venue),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
