import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Gestão de usuários (somente ADMIN): lista e acesso ao formulário.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);

    return AppScreen(
      title: 'Usuários',
      titleVariant: AppScreenTitleVariant.titleLg,
      actions: [
        FilledButton.icon(
          onPressed: () => context.go('/users/new'),
          icon: const Icon(Icons.add),
          label: const Text('Novo'),
        ),
      ],
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
                    final user = items[index];
                    return _userCard(context, user);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _userCard(BuildContext context, User user) {
    final role = _roleLabel(user.role);
    return Card(
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
              child: Icon(_roleIcon(user.role),
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _roleChip(user.role, role),
          ],
        ),
      ),
    );
  }

  Widget _roleChip(String role, String label) {
    final color = switch (role) {
      'ADMIN' => AppColors.danger,
      'MESA' => AppColors.success,
      _ => AppColors.primary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, color: color),
      ),
    );
  }

  IconData _roleIcon(String role) => switch (role) {
        'ADMIN' => Icons.admin_panel_settings,
        'MESA' => Icons.sports_score,
        _ => Icons.person,
      };
}

/// Rótulo pt-BR de um papel de usuário.
String _roleLabel(String role) => switch (role) {
      'ADMIN' => 'Administrador',
      'MESA' => 'Mesa',
      'ORGANIZER' => 'Organizador',
      _ => role,
    };
