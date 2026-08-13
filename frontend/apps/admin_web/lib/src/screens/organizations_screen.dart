import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Gestão de organizações: lista e acesso ao formulário de criação/edição.
class OrganizationsScreen extends ConsumerWidget {
  const OrganizationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizations = ref.watch(organizationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Organizações')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nova organização',
        onPressed: () => context.push('/organizations/new'),
        child: const Icon(Icons.add),
      ),
      body: organizations.when(
        loading: () => const AppLoading(message: 'Carregando organizações...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar as organizações',
          onRetry: () => ref.invalidate(organizationsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhuma organização cadastrada',
              icon: Icons.business,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final organization = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(organization.tradeName),
                  subtitle: Text(organization.legalName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    '/organizations/${organization.id}',
                    extra: organization,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
