import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Tela exclusiva do super usuário (ADMIN) para aprovar/rejeitar contas.
class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingUsersProvider);

    return AppScreen(
      title: 'Aprovações',
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem('Aprovações'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          pending.when(
            loading: () =>
                const AppLoading(message: 'Carregando pendências...'),
            error: (error, stackTrace) => AppErrorState(
              message: 'Não foi possível carregar as pendências',
              onRetry: () => ref.invalidate(pendingUsersProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const KicksterEmptyState(
                  message: 'Nenhuma conta aguardando aprovação',
                  description:
                      'Contas criadas por novos usuários aparecem aqui '
                      'para revisão.',
                  icon: Icons.verified_outlined,
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
                          '${items.length} '
                          '${items.length == 1 ? 'conta' : 'contas'} pendentes',
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
                          onChanged: (value) => setState(() => _query = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    const AppEmptyState(
                      message: 'Nenhuma conta encontrada',
                      icon: Icons.search_off,
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 600 ? 2 : 1;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: filtered.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 200,
                              ),
                          itemBuilder: (context, index) {
                            final user = filtered[index];
                            return _approvalCard(context, ref, user);
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

  Widget _approvalCard(BuildContext context, WidgetRef ref, User user) {
    final roleLabel = _roleLabel(user.role);
    final dateText = _formatDateTime(user.createdAt);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user.name.isNotEmpty)
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
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${roleLabel.isNotEmpty ? '$roleLabel · ' : ''}Solicitado em $dateText',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  // TODO(#457): variante danger/semantic no KicksterButton
                  // quando o core evoluir.
                  child: FilledButton.icon(
                    onPressed: () => _reject(context, ref, user),
                    icon: const Icon(Icons.close),
                    label: const Text('Rejeitar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  // TODO(#457): variante danger/semantic no KicksterButton
                  // quando o core evoluir.
                  child: FilledButton.icon(
                    onPressed: () => _approve(context, ref, user),
                    icon: const Icon(Icons.check),
                    label: const Text('Aprovar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref, User user) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authApiProvider).approveUser(user.id);
      ref.invalidate(pendingUsersProvider);
      ref.invalidate(usersProvider);
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('${user.name} aprovado!')),
        );
      }
    } on RepositoryException catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível aprovar.')),
        );
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, User user) async {
    final confirmed = await showKicksterConfirm(
      context: context,
      title: 'Rejeitar conta',
      content: 'Rejeitar ${user.email}?\nA conta será recusada.',
      confirmLabel: 'Rejeitar',
      danger: true,
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authApiProvider).rejectUser(user.id);
      ref.invalidate(pendingUsersProvider);
      ref.invalidate(usersProvider);
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('${user.name} rejeitado.')),
        );
      }
    } on RepositoryException catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível rejeitar.')),
        );
      }
    }
  }
}

String _roleLabel(String role) => switch (role) {
  'ADMIN' => 'Administrador',
  'MESA' => 'Mesa',
  'ORGANIZER' => 'Organizador',
  _ => role,
};

String _formatDateTime(DateTime? value) {
  if (value == null) return 'agora';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} $hour:$minute';
}
