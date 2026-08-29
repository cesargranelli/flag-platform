import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Gestão de usuários (somente ADMIN): lista e acesso ao formulário.
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();
  String _query = '';

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
          // Conteúdo
          users.when(
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
              final query = _query.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? items
                  : items
                      .where(
                        (u) =>
                            u.name.toLowerCase().contains(query) ||
                            u.email.toLowerCase().contains(query),
                      )
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
                          '${items.length} ${items.length == 1 ? 'usuário' : 'usuários'}',
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
                      message: 'Nenhum usuário encontrado',
                      icon: Icons.search_off,
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns =
                            constraints.maxWidth >= 600 ? 2 : 1;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
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
                            final user = filtered[index];
                            return _userCard(context, user);
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
    return KicksterBadge(label: label, color: color);
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
