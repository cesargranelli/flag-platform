import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../utils/mutation.dart';
import '../widgets/app_entity_list_screen.dart';
import '../widgets/app_screen.dart';

/// Gestão de organizações: cards de acesso e navegação para o detalhe.
///
/// Listagem em grid de cards (padrão web) com filtro por tipo;
/// clicar navega para a tela de detalhe da organização.
class OrganizationsScreen extends ConsumerStatefulWidget {
  const OrganizationsScreen({super.key});

  @override
  ConsumerState<OrganizationsScreen> createState() =>
      _OrganizationsScreenState();
}

class _OrganizationsScreenState extends ConsumerState<OrganizationsScreen> {
  OrganizationType? _typeFilter;
  bool _showDisabled = false;
  final _searchController = TextEditingController();

  static const _scope = 'organizations';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        ref.watch(authControllerProvider.select((a) => a.state.user?.role)) ==
        UserRole.admin;
    final showDisabled = isAdmin && _showDisabled;
    final organizations = showDisabled
        ? ref.watch(organizationsAdminProvider(true))
        : ref.watch(organizationsProvider);

    return AppScreen(
      title: 'Organizações',
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem('Organizações'),
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
                onPressed: () => context.go('/organizations/new'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Conteúdo (Expanded para dar altura finita ao grid)
          Expanded(
            child: organizations.when(
              loading: () =>
                  const AppLoading(message: 'Carregando organizações...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar as organizações',
                onRetry: () => showDisabled
                    ? ref.invalidate(organizationsAdminProvider(true))
                    : ref.invalidate(organizationsProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return KicksterEmptyState(
                    icon: Icons.business,
                    message: 'Nenhuma organização cadastrada',
                    description:
                        'Crie a primeira organização para começar a usar.',
                    action: KicksterButton(
                      label: 'Criar organização',
                      icon: Icons.add,
                      onPressed: () => context.go('/organizations/new'),
                    ),
                  );
                }
                return AppEntityListScreen<Organization>(
                  items: items,
                  cardBuilder: (organization) =>
                      _organizationCard(context, organization, isAdmin),
                  searchField: _searchController,
                  emptyMessage: 'Nenhuma organização encontrada',
                  searchWidth: 220,
                  toolbarLeading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8),
                      if (isAdmin) ...[
                        Tooltip(
                          message: 'Exibir organizações desativadas',
                          child: IconButton(
                            isSelected: _showDisabled,
                            selectedIcon: const Icon(Icons.visibility),
                            icon: const Icon(Icons.visibility_off_outlined),
                            tooltip: 'Desativadas',
                            onPressed: () =>
                                setState(() => _showDisabled = !_showDisabled),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      SizedBox(
                        width: 260,
                        child: KicksterDropdown<OrganizationType?>(
                          label: 'Filtrar por tipo',
                          value: _typeFilter,
                          values: [null, ...OrganizationType.values],
                          labels: [
                            'Todas as organizações',
                            ...OrganizationType.values.map((t) => t.label),
                          ],
                          icons: [
                            null,
                            ...OrganizationType.values
                                .map(organizationTypeIcon),
                          ],
                          onChanged: (value) =>
                              setState(() => _typeFilter = value),
                        ),
                      ),
                    ],
                  ),
                  filter: (all, query) => all
                      .where((o) {
                        if (_typeFilter != null &&
                            o.organizationType != _typeFilter) {
                          return false;
                        }
                        if (query.isEmpty) return true;
                        return o.tradeName.toLowerCase().contains(query) ||
                            o.legalName.toLowerCase().contains(query);
                      })
                      .toList(growable: false),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Card de organização no padrão Kickster (core #439): ícone do tipo,
  /// nome fantasia + nome legal e, à direita, badge de desativada (quando
  /// inativa) e menu de gestão para ADMIN.
  Widget _organizationCard(
    BuildContext context,
    Organization organization,
    bool isAdmin,
  ) {
    final isDisabled = organization.status == OrganizationStatus.inactive;
    return KicksterCard(
      icon: organizationTypeIcon(organization.organizationType),
      title: organization.tradeName,
      subtitle: organization.legalName,
      onTap: () => context.push(
        '/organizations/${organization.id}',
        extra: organization,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDisabled) _disabledBadge(),
          if (isAdmin)
            PopupMenuButton<String>(
              tooltip: 'Ações',
              onSelected: (value) async {
                if (value == 'deactivate') {
                  final ok = await _confirm(
                    context,
                    'Desativar organização',
                    '"${organization.tradeName}" ficará invisível '
                        'para os demais usuários até ser reativada.',
                  );
                  if (ok == true) await _deactivate(organization);
                } else if (value == 'reactivate') {
                  await _reactivate(organization);
                }
              },
              itemBuilder: (_) => [
                if (!isDisabled)
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: Text('Desativar'),
                  ),
                if (isDisabled)
                  const PopupMenuItem(
                    value: 'reactivate',
                    child: Text('Reativar'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _disabledBadge() {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: KicksterBadge(label: 'Desativada', color: AppColors.danger),
    );
  }

  Future<bool?> _confirm(BuildContext context, String title, String message) {
    return showKicksterConfirm(
      context: context,
      title: title,
      content: message,
      confirmLabel: 'Desativar',
      danger: true,
    );
  }

  void _invalidateLists() {
    ref.invalidate(organizationsProvider);
    ref.invalidate(organizationsAdminProvider(true));
  }

  Future<void> _deactivate(Organization organization) => _toggleActive(
        organization,
        activate: false,
        successMessage: '${organization.tradeName} desativada.',
        errorMessage: 'Não foi possível desativar a organização.',
      );

  Future<void> _reactivate(Organization organization) => _toggleActive(
        organization,
        activate: true,
        successMessage: '${organization.tradeName} reativada.',
        errorMessage: 'Não foi possível reativar a organização.',
      );

  Future<void> _toggleActive(
    Organization organization, {
    required bool activate,
    required String successMessage,
    required String errorMessage,
  }) async {
    await runMutation(
      context,
      ref: ref,
      scope: _scope,
      action: () => activate
          ? ref.read(organizationApiProvider).reactivate(organization.id)
          : ref.read(organizationApiProvider).deactivate(organization.id),
      successMessage: successMessage,
      errorMessage: errorMessage,
      progressId: organization.id,
      onSuccess: _invalidateLists,
    );
  }
}
