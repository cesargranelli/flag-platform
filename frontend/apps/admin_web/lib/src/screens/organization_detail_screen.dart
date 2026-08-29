import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Detalhe de uma organização em sessões espelhando o wizard (#323),
/// com navegação por cards no topo: tocar em uma sessão troca o bloco
/// exibido — a tela mostra APENAS o conteúdo da sessão ativa (#326).
///
/// A edição é uma ação explícita na tela (organizações não são editáveis
/// após a criação — V250).
class OrganizationDetailScreen extends ConsumerStatefulWidget {
  const OrganizationDetailScreen({super.key, this.organizationId, this.organization});

  final String? organizationId;
  final Organization? organization;

  @override
  ConsumerState<OrganizationDetailScreen> createState() =>
      _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState
    extends ConsumerState<OrganizationDetailScreen> {
  static const _sessions = [
    'Identificação',
    'Presidente',
    'Contato',
    'Localização',
    'Identidade',
  ];

  /// Ícones das sessões (issue #326), paralelos a [_sessions].
  static const _sessionIcons = <IconData>[
    Icons.business_outlined,
    Icons.person_outline,
    Icons.contact_mail_outlined,
    Icons.location_on_outlined,
    Icons.palette_outlined,
  ];

  /// Índice da sessão ativa — único bloco exibido no corpo da tela (#326).
  int _activeSession = 0;

  @override
  Widget build(BuildContext context) {
    final org = widget.organization;
    final orgFuture = org != null
        ? null
        : ref.watch(organizationProvider(widget.organizationId!));

    return AppScreen(
      title: org?.tradeName ?? 'Organização',
      backTarget: '/organizations',
      backLabel: 'Organizações',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: AppLayout.form(
              child: AppStepIndicator(
                titles: _sessions,
                icons: _sessionIcons,
                currentStep: _activeSession,
                showDoneState: false,
                onStepTap: (index) => setState(() => _activeSession = index),
              ),
            ),
          ),
          Expanded(
            child: orgFuture == null
                ? _buildDetail(context, org!)
                : orgFuture.when(
                    loading: () => const AppLoading(
                      message: 'Carregando organização...',
                    ),
                    error: (error, stackTrace) => AppErrorState(
                      message: 'Não foi possível carregar a organização',
                      onRetry: () => ref.invalidate(
                        organizationProvider(widget.organizationId!),
                      ),
                    ),
                    data: (org) => _buildDetail(context, org),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Organization org) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppLayout.detail(
        child: switch (_activeSession) {
          0 => _identificacaoCard(org),
          1 => _presidenteCard(org),
          2 => _contatoCard(org),
          3 => _localizacaoCard(org),
          _ => _identidadeCard(org),
        },
      ),
    );
  }

  /// Sessão 1 — Identificação (#323): card hero consolidado + dados.
  Widget _identificacaoCard(Organization org) {
    return Card(
      child: Container(
        constraints: const BoxConstraints(minHeight: 160),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identificação',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
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
            if (org.abbreviation != null && org.abbreviation!.isNotEmpty)
              AppInfoRow(label: 'Sigla', value: org.abbreviation!),
            if (org.organizationType != null)
              AppInfoRow(label: 'Tipo', value: org.organizationType!.label),
            if (org.document != null && org.document!.isNotEmpty)
              AppInfoRow(label: 'CNPJ', value: org.document!),
            if (org.createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Criada em ${_formatDate(org.createdAt!)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Sessão 2 — Presidente (#323).
  Widget _presidenteCard(Organization org) {
    return AppInfoCard(
      title: 'Presidente',
      children: [
        if (org.presidentName != null && org.presidentName!.isNotEmpty)
          AppInfoRow(label: 'Nome', value: org.presidentName!),
        if (org.presidentCpf != null && org.presidentCpf!.isNotEmpty)
          AppInfoRow(label: 'CPF', value: org.presidentCpf!),
      ],
    );
  }

  /// Sessão 3 — Contato (#323).
  Widget _contatoCard(Organization org) {
    return AppInfoCard(
      title: 'Contato',
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

  /// Sessão 4 — Localização (#323): movida de Identificação.
  Widget _localizacaoCard(Organization org) {
    return AppInfoCard(
      title: 'Localização',
      children: [
        AppInfoRow(label: 'País', value: org.country),
        if (org.state != null && org.state!.isNotEmpty)
          AppInfoRow(label: 'Estado', value: org.state!),
        if (org.city != null && org.city!.isNotEmpty)
          AppInfoRow(label: 'Cidade', value: org.city!),
      ],
    );
  }

  /// Sessão 5 — Identidade (#323): renomeado de 'Visual'.
  Widget _identidadeCard(Organization org) {
    return AppInfoCard(
      title: 'Identidade',
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

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
