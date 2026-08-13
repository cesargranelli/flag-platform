import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Gestão de atletas: lista e acesso ao formulário.
class AthletesScreen extends ConsumerWidget {
  const AthletesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final athletes = ref.watch(athletesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Atletas')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo atleta',
        onPressed: () => context.push('/athletes/new'),
        child: const Icon(Icons.add),
      ),
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
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final athlete = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(athlete.name),
                  subtitle: Text(
                    '${athlete.nickname ?? ''}${athlete.number != null ? ' · ${athlete.number}' : ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push('/athletes/${athlete.id}', extra: athlete),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
