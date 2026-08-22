import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/app_back_button.dart';

/// Detalhe de uma organizaÃ§Ã£o: apresenta os dados e oferece a ediÃ§Ã£o.
///
/// A navegaÃ§Ã£o para esta tela NÃƒO abre o formulÃ¡rio de ediÃ§Ã£o diretamente;
/// a ediÃ§Ã£o Ã© uma aÃ§Ã£o explÃ­cita na tela.
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
        title: Text(organization?.tradeName ?? 'OrganizaÃ§Ã£o'),
        leading: AppBackButton(fallbackRoute: '/organizations'),
      ),
      body: orgFuture == null
          ? _buildDetail(context, organization!)
          : orgFuture.when(
              loading: () => const AppLoading(message: 'Carregando organizaÃ§Ã£o...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'NÃ£o foi possÃ­vel carregar a organizaÃ§Ã£o',
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
      child: AppLayout.detail(
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
                    // V250: organizaÃ§Ãµes nÃ£o sÃ£o editÃ¡veis apÃ³s a criaÃ§Ã£o.
                  ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _infoCard(
            'IdentificaÃ§Ã£o',
            [
              _row('Nome fantasia', org.tradeName),
              _row('RazÃ£o social', org.legalName),
              if (org.abbreviation != null && org.abbreviation!.isNotEmpty)
                _row('Sigla', org.abbreviation!),
              if (org.organizationType != null)
                _row('Tipo', org.organizationType!.label),
              if (org.document != null && org.document!.isNotEmpty)
                _row('CNPJ', org.document!),
              _row('PaÃ­s', org.country),
              if (org.state != null && org.state!.isNotEmpty) _row('Estado', org.state!),
              if (org.city != null && org.city!.isNotEmpty) _row('Cidade', org.city!),
            ],
          ),
          const SizedBox(height: 12),
          _infoCard(
            'Presidente',
            [
              if (org.presidentName != null && org.presidentName!.isNotEmpty)
                _row('Nome', org.presidentName!),
              if (org.presidentCpf != null && org.presidentCpf!.isNotEmpty)
                _row('CPF', org.presidentCpf!),
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
              if (org.locale.isNotEmpty) _row('Locale', org.locale),
              if (org.primaryColor != null && org.primaryColor!.isNotEmpty)
                _colorRow('Cor primÃ¡ria', org.primaryColor!),
              if (org.secondaryColor != null && org.secondaryColor!.isNotEmpty)
                _colorRow('Cor secundÃ¡ria', org.secondaryColor!),
              if (org.tertiaryColor != null && org.tertiaryColor!.isNotEmpty)
                _colorRow('Cor terciÃ¡ria', org.tertiaryColor!),
              if (org.quaternaryColor != null &&
                  org.quaternaryColor!.isNotEmpty)
                _colorRow('Cor quaternÃ¡ria', org.quaternaryColor!),
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

  /// Linha de cor: swatch arredondado preenchido + valor hex legÃ­vel.
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

  /// Aceita "#RRGGBB" ou "RRGGBB"; retorna null se invÃ¡lido.
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
