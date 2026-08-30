import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../utils/date_formats.dart';
import '../utils/mutation.dart';
import '../widgets/app_entity_list_screen.dart';
import '../widgets/app_screen.dart';

/// Tela exclusiva do super usuário (ADMIN) para aprovar/rejeitar contas.
class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  final _searchController = TextEditingController();

  static const _scope = 'approvals';

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
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem('Aprovações'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conteúdo (Expanded para dar altura finita ao grid)
          Expanded(
            child: pending.when(
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
                return AppEntityListScreen<User>(
                  items: items,
                  cardBuilder: (user) => _approvalCard(context, ref, user),
                  searchField: _searchController,
                  countLabel: 'contas pendentes',
                  countLabelSingular: 'conta pendente',
                  emptyMessage: 'Nenhuma conta encontrada',
                  mainAxisExtent: 200,
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

  Widget _approvalCard(BuildContext context, WidgetRef ref, User user) {
    final roleLabel = user.role.label;
    final dateText = formatBrShortDateTime(user.createdAt);

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
                    onPressed:
                        ref.watch(mutationProgressProvider(_scope)).contains(user.id)
                            ? null
                            : () => _reject(context, ref, user),
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
                    onPressed:
                        ref.watch(mutationProgressProvider(_scope)).contains(user.id)
                            ? null
                            : () => _approve(context, ref, user),
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
    await runMutation(
      context,
      ref: ref,
      scope: _scope,
      action: () => ref.read(authApiProvider).approveUser(user.id),
      successMessage: '${user.name} aprovado!',
      errorMessage: 'Não foi possível aprovar.',
      progressId: user.id,
      onSuccess: () {
        ref.invalidate(pendingUsersProvider);
        ref.invalidate(usersProvider);
      },
    );
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

    await runMutation(
      context,
      ref: ref,
      scope: _scope,
      action: () => ref.read(authApiProvider).rejectUser(user.id),
      successMessage: '${user.name} rejeitado.',
      errorMessage: 'Não foi possível rejeitar.',
      progressId: user.id,
      onSuccess: () {
        ref.invalidate(pendingUsersProvider);
        ref.invalidate(usersProvider);
      },
    );
  }
}
