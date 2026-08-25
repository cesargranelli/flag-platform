import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
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

  bool get _isAdmin =>
      ref.read(authControllerProvider).state.user?.role == 'ADMIN';

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authControllerProvider).state.user?.role == 'ADMIN';
    final showDisabled = isAdmin && _showDisabled;
    final organizations = showDisabled
        ? ref.watch(organizationsAdminProvider(true))
        : ref.watch(organizationsProvider);

    return AppScreen(
      title: 'Organizações',
      leading: BackButton(onPressed: () => context.go('/')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nova organização',
        onPressed: () => context.push('/organizations/new'),
        child: const Icon(Icons.add),
      ),
      body: organizations.when(
        loading: () => const AppLoading(message: 'Carregando organizações...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar as organizações',
          onRetry: () => showDisabled
              ? ref.invalidate(organizationsAdminProvider(true))
              : ref.invalidate(organizationsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhuma organização cadastrada',
              icon: Icons.business,
            );
          }
          final filtered = _typeFilter == null
              ? items
              : items
                  .where((o) => o.organizationType == _typeFilter)
                  .toList(growable: false);

          return AppLayout.content(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} de ${items.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (isAdmin)
                        Tooltip(
                          message: 'Exibir organizações desativadas',
                          child: IconButton(
                            isSelected: _showDisabled,
                            selectedIcon: const Icon(Icons.visibility),
                            icon: const Icon(Icons.visibility_off_outlined),
                            tooltip: 'Desativadas',
                            onPressed: () => setState(
                                () => _showDisabled = !_showDisabled),
                          ),
                        ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 260,
                        child: DropdownButtonFormField<OrganizationType?>(
                          initialValue: _typeFilter,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'Filtrar por tipo',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<OrganizationType?>(
                              value: null,
                              child: Text('Todas as organizações'),
                            ),
                            ...OrganizationType.values.map(
                              (t) => DropdownMenuItem<OrganizationType?>(
                                value: t,
                                child: Text(t.label),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _typeFilter = value),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const AppEmptyState(
                          message: 'Nenhuma organização neste tipo',
                          icon: Icons.filter_alt_off_outlined,
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 600 ? 2 : 1;
                            return GridView.builder(
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
                                final organization = filtered[index];
                                return _organizationCard(
                                    context, organization);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _organizationCard(BuildContext context, Organization organization) {
    final isDisabled = organization.status == OrganizationStatus.inactive;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          '/organizations/${organization.id}',
          extra: organization,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.business,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organization.tradeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDisabled
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            decoration:
                                isDisabled ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          organization.legalName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (isDisabled) _disabledBadge(),
                  if (_isAdmin)
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _disabledBadge() {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Desativada',
        style: TextStyle(fontSize: 12, color: AppColors.danger),
      ),
    );
  }

  Future<bool?> _confirm(BuildContext context, String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
  }

  void _invalidateLists() {
    ref.invalidate(organizationsProvider);
    ref.invalidate(organizationsAdminProvider(true));
  }

  Future<void> _deactivate(Organization organization) async {
    try {
      await ref.read(organizationApiProvider).deactivate(organization.id);
      _invalidateLists();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${organization.tradeName} desativada.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não foi possível desativar a organização.')),
        );
      }
    }
  }

  Future<void> _reactivate(Organization organization) async {
    try {
      await ref.read(organizationApiProvider).reactivate(organization.id);
      _invalidateLists();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${organization.tradeName} reativada.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não foi possível reativar a organização.')),
        );
      }
    }
  }
}
