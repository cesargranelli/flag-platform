import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/app_back_button.dart';
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
      leading: AppBackButton(fallbackRoute: '/organizations'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: AppSessionNav(
              sessions: _sessions,
              icons: _sessionIcons,
              activeIndex: _activeSession,
              onTap: (index) => setState(() => _activeSession = index),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Identificação',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
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
            if (org.abbreviation != null && org.abbreviation!.isNotEmpty)
              _row('Sigla', org.abbreviation!),
            if (org.organizationType != null)
              _row('Tipo', org.organizationType!.label),
            if (org.document != null && org.document!.isNotEmpty)
              _row('CNPJ', org.document!),
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
    return _infoCard('Presidente', [
      if (org.presidentName != null && org.presidentName!.isNotEmpty)
        _row('Nome', org.presidentName!),
      if (org.presidentCpf != null && org.presidentCpf!.isNotEmpty)
        _row('CPF', org.presidentCpf!),
    ]);
  }

  /// Sessão 3 — Contato (#323).
  Widget _contatoCard(Organization org) {
    return _infoCard('Contato', [
      if (org.email != null && org.email!.isNotEmpty)
        _row('E-mail', org.email!),
      if (org.phone != null && org.phone!.isNotEmpty)
        _row('Telefone', org.phone!),
      if (org.website != null && org.website!.isNotEmpty)
        _row('Site', org.website!),
      if (org.instagram != null && org.instagram!.isNotEmpty)
        _row('Instagram', org.instagram!),
    ]);
  }

  /// Sessão 4 — Localização (#323): movida de Identificação.
  Widget _localizacaoCard(Organization org) {
    return _infoCard('Localização', [
      _row('País', org.country),
      if (org.state != null && org.state!.isNotEmpty)
        _row('Estado', org.state!),
      if (org.city != null && org.city!.isNotEmpty)
        _row('Cidade', org.city!),
    ]);
  }

  /// Sessão 5 — Identidade (#323): renomeado de 'Visual'.
  Widget _identidadeCard(Organization org) {
    return _infoCard('Identidade', [
      if (org.locale.isNotEmpty) _row('Locale', org.locale),
      if (org.primaryColor != null && org.primaryColor!.isNotEmpty)
        _colorRow('Cor primária', org.primaryColor!),
      if (org.secondaryColor != null && org.secondaryColor!.isNotEmpty)
        _colorRow('Cor secundária', org.secondaryColor!),
      if (org.tertiaryColor != null && org.tertiaryColor!.isNotEmpty)
        _colorRow('Cor terciária', org.tertiaryColor!),
      if (org.quaternaryColor != null && org.quaternaryColor!.isNotEmpty)
        _colorRow('Cor quaternária', org.quaternaryColor!),
      if (org.logoUrl != null && org.logoUrl!.isNotEmpty)
        _row('Logo', org.logoUrl!),
    ]);
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

  /// Linha de cor: swatch arredondado preenchido + valor hex legível.
  Widget _colorRow(String label, String hex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: _parseHex(hex) ?? Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            hex.toUpperCase(),
            style: const TextStyle(fontSize: 13, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  /// Aceita "#RRGGBB" ou "RRGGBB"; retorna null se inválido.
  Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceAll('#', '').trim();
    final value = int.tryParse('FF$clean', radix: 16);
    return value == null ? null : Color(value);
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
