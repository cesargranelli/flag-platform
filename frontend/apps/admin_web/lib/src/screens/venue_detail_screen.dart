import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Detalhe de um campo de jogo: apresenta os dados e oferece a edição.
///
/// O campo não possui exclusão (backend sem DELETE). A edição é uma ação
/// explícita na tela.
class VenueDetailScreen extends ConsumerWidget {
  const VenueDetailScreen({super.key, this.venueId, this.venue});

  final String? venueId;
  final Venue? venue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venueFuture = venue != null
        ? null
        : ref.watch(venueProvider(venueId!));

    return AppScreen(
      title: venue?.name ?? 'Campo',
      backTarget: '/venues',
      backLabel: 'Campos',
      body: venueFuture == null
          ? _buildDetail(context, ref, venue!)
          : venueFuture.when(
              loading: () => const AppLoading(message: 'Carregando campo...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar o campo',
                onRetry: () => ref.invalidate(venueProvider(venueId!)),
              ),
              data: (venue) => _buildDetail(context, ref, venue),
            ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Venue venue) {
    final organizations = ref.watch(organizationsProvider);
    final orgName = organizations.valueOrNull
            ?.where((o) => o.id == venue.organizationId)
            .map((o) => o.tradeName)
            .firstOrNull ??
        '';

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
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.sports_soccer,
                              color: AppColors.primary, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                venue.name,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              if (orgName.isNotEmpty)
                                Text(
                                  orgName,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.go(
                        '/venues/${venue.id}/edit',
                        extra: venue,
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
              'Informações',
              [
                if (orgName.isNotEmpty) _row('Organização', orgName),
                _row('Endereço', venue.address?.isNotEmpty == true ? venue.address! : '—'),
                if (venue.mapsUrl != null && venue.mapsUrl!.isNotEmpty)
                  _row('URL do mapa', venue.mapsUrl!),
              ],
            ),
            if (venue.mapsUrl != null && venue.mapsUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openMap(context, venue.mapsUrl!),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Abrir no mapa'),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Criado em ${_formatDate(venue.createdAt)}'
              '${venue.updatedAt != null ? ' • Atualizado em ${_formatDate(venue.updatedAt)}' : ''}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMap(BuildContext context, String mapsUrl) async {
    final uri = Uri.tryParse(mapsUrl);
    if (uri == null || !(uri.hasScheme && uri.hasAuthority)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o mapa')),
        );
      }
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o mapa')),
      );
    }
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
