import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../utils/date_formats.dart';
import '../widgets/app_screen.dart';

/// Detalhe de uma organização em página única (#455): todas as seções
/// (identificação, presidente, contato, localização, identidade) empilhadas
/// com títulos de seção — o scroll é do body, sem barras internas.
///
/// A edição é uma ação explícita na tela (organizações não são editáveis
/// após a criação — V250).
class OrganizationDetailScreen extends ConsumerWidget {
  const OrganizationDetailScreen({
    super.key,
    this.organizationId,
    this.organization,
  });

  final String? organizationId;
  final Organization? organization;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final org = organization;
    final orgFuture =
        org != null ? null : ref.watch(organizationProvider(organizationId!));

    // Breadcrumb dinâmico com nome da organização
    final orgName = org?.tradeName;
    final breadcrumb = [
      const BreadcrumbItem('Início', route: '/'),
      const BreadcrumbItem(AppStrings.organizations, route: '/organizations'),
      if (orgName != null) BreadcrumbItem(orgName),
    ];

    return AppScreen(
      title: org?.tradeName ?? 'Organização',
      breadcrumb: breadcrumb,
      body: orgFuture == null
          ? _buildDetail(context, org!)
          : orgFuture.when(
              loading: () => const AppLoading(
                message: 'Carregando organização...',
              ),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar a organização',
                onRetry: () => ref.invalidate(
                  organizationProvider(organizationId!),
                ),
              ),
              data: (org) => _buildDetail(context, org),
            ),
    );
  }

  /// Página única: seções empilhadas, scroll do body (#455).
  Widget _buildDetail(BuildContext context, Organization org) {
    return AppLayout.detail(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _section(
            title: 'Identificação',
            icon: Icons.business_outlined,
            child: _identificacaoCard(org),
          ),
          _section(
            title: 'Presidente',
            icon: Icons.person_outline,
            child: _presidenteCard(org),
          ),
          _section(
            title: 'Contato',
            icon: Icons.contact_mail_outlined,
            child: _contatoCard(org),
          ),
          _section(
            title: 'Localização',
            icon: Icons.location_on_outlined,
            child: _localizacaoCard(org),
          ),
          _section(
            title: 'Identidade',
            icon: Icons.palette_outlined,
            child: _identidadeCard(org),
          ),
        ],
      ),
    );
  }

  /// Título de seção (titleMedium) + card, separados por espaçamento padrão.
  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KicksterSectionTitle(title: title, icon: icon),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 20),
      ],
    );
  }

  /// Seção 1 — Identificação (#323): card hero consolidado + dados.
  Widget _identificacaoCard(Organization org) {
    return Card(
      child: Container(
        constraints: const BoxConstraints(minHeight: 160),
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
                  child: Icon(
                      organizationTypeIcon(org.organizationType),
                      color: AppColors.primary,
                      size: 36,
                    ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        org.tradeName,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700),
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
            if (org.abbreviation != null && org.abbreviation!.isNotEmpty)
              AppInfoRow(label: 'Sigla', value: org.abbreviation!),
            if (org.organizationType != null)
              AppInfoRow(label: 'Tipo', value: org.organizationType!.label),
            if (org.document != null && org.document!.isNotEmpty)
              AppInfoRow(label: 'CNPJ', value: org.document!),
            if (org.createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Criada em ${formatBrDate(org.createdAt!)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Seção 2 — Presidente (#323).
  Widget _presidenteCard(Organization org) {
    return AppInfoCard(
      children: [
        if (org.presidentName != null && org.presidentName!.isNotEmpty)
          AppInfoRow(label: 'Nome', value: org.presidentName!),
        if (org.presidentCpf != null && org.presidentCpf!.isNotEmpty)
          AppInfoRow(label: 'CPF', value: org.presidentCpf!),
      ],
    );
  }

  /// Seção 3 — Contato (#323).
  Widget _contatoCard(Organization org) {
    return AppInfoCard(
      children: [
        if (org.email != null && org.email!.isNotEmpty)
          AppInfoRow(label: 'E-mail', value: org.email!),
        if (org.phone != null && org.phone!.isNotEmpty)
          AppInfoRow(label: 'Telefone', value: org.phone!),
        if (org.website != null && org.website!.isNotEmpty)
          AppInfoRow(label: 'Site', value: org.website!),
        if (org.instagram != null && org.instagram!.isNotEmpty)
          AppInfoRow(label: 'Instagram', value: org.instagram!),
      ],
    );
  }

  /// Seção 4 — Localização (#323): movida de Identificação.
  Widget _localizacaoCard(Organization org) {
    return AppInfoCard(
      children: [
        AppInfoRow(label: 'País', value: org.country),
        if (org.state != null && org.state!.isNotEmpty)
          AppInfoRow(label: 'Estado', value: org.state!),
        if (org.city != null && org.city!.isNotEmpty)
          AppInfoRow(label: 'Cidade', value: org.city!),
      ],
    );
  }

  /// Seção 5 — Identidade (#323): renomeado de 'Visual'.
  Widget _identidadeCard(Organization org) {
    return AppInfoCard(
      children: [
        if (org.locale.isNotEmpty) AppInfoRow(label: 'Locale', value: org.locale),
        if (org.primaryColor != null && org.primaryColor!.isNotEmpty)
          AppInfoColorRow(label: 'Cor primária', hex: org.primaryColor!),
        if (org.secondaryColor != null && org.secondaryColor!.isNotEmpty)
          AppInfoColorRow(label: 'Cor secundária', hex: org.secondaryColor!),
        if (org.tertiaryColor != null && org.tertiaryColor!.isNotEmpty)
          AppInfoColorRow(label: 'Cor terciária', hex: org.tertiaryColor!),
        if (org.quaternaryColor != null && org.quaternaryColor!.isNotEmpty)
          AppInfoColorRow(label: 'Cor quaternária', hex: org.quaternaryColor!),
        if (org.logoUrl != null && org.logoUrl!.isNotEmpty)
          AppInfoRow(label: 'Logo', value: org.logoUrl!),
      ],
    );
  }
}