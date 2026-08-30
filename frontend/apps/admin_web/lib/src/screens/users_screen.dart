import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_entity_list_screen.dart';
import '../widgets/app_screen.dart';

/// Gestão de usuários (somente ADMIN): lista e acesso ao formulário.
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider);

    return AppScreen(
      title: 'Usuários',
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem('Usuários'),
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
                onPressed: () => context.go('/users/new'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Conteúdo (Expanded para dar altura finita ao grid)
          Expanded(
            child: users.when(
              loading: () =>
                  const AppLoading(message: 'Carregando usuários...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar os usuários',
                onRetry: () => ref.invalidate(usersProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return KicksterEmptyState(
                    icon: Icons.people_outline,
                    message: 'Nenhum usuário cadastrado',
                    description:
                        'Crie o primeiro usuário para começar a usar.',
                    action: KicksterButton(
                      label: 'Criar usuário',
                      icon: Icons.add,
                      onPressed: () => context.go('/users/new'),
                    ),
                  );
                }
                return AppEntityListScreen<User>(
                  items: items,
                  cardBuilder: (user) => _userCard(context, user),
                  searchField: _searchController,
                  countLabel: 'usuários',
                  countLabelSingular: 'usuário',
                  emptyMessage: 'Nenhum usuário encontrado',
                  filter: (all, query) => query.isEmpty
                      ? all
                      : all
                          .where(
                            (u) =>
                                u.name.toLowerCase().contains(query) ||
                                u.email.toLowerCase().contains(query),
                          )
                          .toList(growable: false),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _userCard(BuildContext context, User user) {
    final role = user.role.label;
    return Card(
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_roleIcon(user.role),
                  color: AppColors.primary, size: 24),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
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

  Widget _roleChip(UserRole role, String label) {
    final color = switch (role) {
      UserRole.admin => AppColors.danger,
      UserRole.mesa => AppColors.success,
      UserRole.organizer => AppColors.primary,
    };
    return KicksterBadge(label: label, color: color);
  }

  IconData _roleIcon(UserRole role) => switch (role) {
        UserRole.admin => Icons.admin_panel_settings,
        UserRole.mesa => Icons.sports_score,
        UserRole.organizer => Icons.person,
      };
}
