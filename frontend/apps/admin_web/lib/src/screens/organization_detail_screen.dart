import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Detalhe de uma organização: apresenta os dados e oferece a edição.
///
/// A navegação para esta tela NÃO abre o formulário de edição diretamente;
/// a edição é uma ação explícita na tela.
class OrganizationDetailScreen extends ConsumerWidget {
  const OrganizationDetailScreen({super.key, this.organizationId, this.organization});

  final String? organizationId;
  final Organization? organization;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgFuture = organization != null
        ? null
        : ref.watch(organizationProvider(organizationId!));

    return Scaffold(
      appBar: AppBar(
        title: Text(organization?.tradeName ?? 'Organização'),
        leading: const BackButton(),
      ),
      body: orgFuture == null
          ? _buildDetail(context, organization!)
          : orgFuture.when(
              loading: () => const AppLoading(message: 'Carregando organização...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar a organização',
                onRetry: () =>
                    ref.invalidate(organizationProvider(organizationId!)),
              ),
              data: (org) => _buildDetail(context, org),
            ),
    );
  }

  Widget _buildDetail(BuildContext context, Organization org) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.business,
                            color: AppColors.primary, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              org.tradeName,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              org.legalName,
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.push(
                      '/organizations/${org.id}/edit',
                      extra: org,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar dados'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _infoCard(
            'Identificação',
            [
              _row('Nome fantasia', org.tradeName),
              _row('Razão social', org.legalName),
              if (org.abbreviation != null && org.abbreviation!.isNotEmpty)
                _row('Sigla', org.abbreviation!),
              if (org.organizationType != null)
                _row('Tipo', org.organizationType!.name),
              _row('País', org.country),
              if (org.state != null && org.state!.isNotEmpty) _row('Estado', org.state!),
              if (org.city != null && org.city!.isNotEmpty) _row('Cidade', org.city!),
            ],
          ),
          const SizedBox(height: 12),
          _infoCard(
            'Contato',
            [
              if (org.email != null && org.email!.isNotEmpty)
                _row('E-mail', org.email!),
              if (org.phone != null && org.phone!.isNotEmpty)
                _row('Telefone', org.phone!),
              if (org.website != null && org.website!.isNotEmpty)
                _row('Site', org.website!),
              if (org.instagram != null && org.instagram!.isNotEmpty)
                _row('Instagram', org.instagram!),
            ],
          ),
          const SizedBox(height: 12),
          _infoCard(
            'Visual',
            [
              if (org.timezone.isNotEmpty) _row('Timezone', org.timezone),
              if (org.locale.isNotEmpty) _row('Locale', org.locale),
              if (org.primaryColor != null && org.primaryColor!.isNotEmpty)
                _row('Cor primária', org.primaryColor!),
              if (org.secondaryColor != null && org.secondaryColor!.isNotEmpty)
                _row('Cor secundária', org.secondaryColor!),
              if (org.logoUrl != null && org.logoUrl!.isNotEmpty)
                _row('Logo', org.logoUrl!),
            ],
          ),
          const SizedBox(height: 12),
          if (org.createdAt != null)
            Text(
              'Criada em ${_formatDate(org.createdAt!)}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
