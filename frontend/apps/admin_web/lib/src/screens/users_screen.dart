import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Gestão de usuários (somente ADMIN): lista e acesso ao formulário.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Usuários')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo usuário',
        onPressed: () => context.push('/users/new'),
        child: const Icon(Icons.add),
      ),
      body: users.when(
        loading: () => const AppLoading(message: 'Carregando usuários...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar os usuários',
          onRetry: () => ref.invalidate(usersProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhum usuário cadastrado',
              icon: Icons.people_outline,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final user = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(user.name),
                  subtitle: Text('${user.email} · ${user.role}'),
                  trailing: Icon(_roleIcon(user.role)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _roleIcon(String role) => switch (role) {
        'ADMIN' => Icons.admin_panel_settings,
        'MESA' => Icons.sports_score,
        _ => Icons.person,
      };
}
