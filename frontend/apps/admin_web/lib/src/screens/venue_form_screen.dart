import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Formulário de criação/edição de campo de jogo.
class VenueFormScreen extends ConsumerStatefulWidget {
  const VenueFormScreen({super.key, this.venueId, this.venue});

  final String? venueId;
  final Venue? venue;

  @override
  ConsumerState<VenueFormScreen> createState() => _VenueFormScreenState();
}

class _VenueFormScreenState extends ConsumerState<VenueFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _mapsUrl;
  String? _organizationId;
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.venueId != null || widget.venue != null;

  @override
  void initState() {
    super.initState();
    final venue = widget.venue;
    _name = TextEditingController(text: venue?.name ?? '');
    _address = TextEditingController(text: venue?.address ?? '');
    _mapsUrl = TextEditingController(text: venue?.mapsUrl ?? '');
    _organizationId = venue?.organizationId;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _mapsUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final organizationId = _organizationId;
    if (organizationId == null) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(venueApiProvider);
      final id = widget.venueId ?? widget.venue?.id;
      if (id == null) {
        await api.create(
          organizationId: organizationId,
          name: _name.text.trim(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          mapsUrl: _mapsUrl.text.trim().isEmpty ? null : _mapsUrl.text.trim(),
        );
      } else {
        await api.update(
          id,
          organizationId: organizationId,
          name: _name.text.trim(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          mapsUrl: _mapsUrl.text.trim().isEmpty ? null : _mapsUrl.text.trim(),
        );
      }
      ref.invalidate(venuesProvider);
      if (mounted) {
        if (id != null) {
          // Volta para o detalhe recarregado (busca fresca via provider).
          context.go('/venues/$id');
        } else {
          context.pop();
        }
      }
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível salvar o campo.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _validateMapsUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    final valid = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return valid ? null : 'Informe uma URL válida (http/https)';
  }

  @override
  Widget build(BuildContext context) {
    final organizations = ref.watch(organizationsProvider);

    return AppScreen(
      title: _isEditing ? 'Editar campo' : 'Novo campo',
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem(AppStrings.venues, route: '/venues'),
        BreadcrumbItem('Formulário'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppLayout.form(
        child: Form(
          key: _formKey,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                organizations.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => AppErrorState(
                    message: 'Erro ao carregar organizações',
                    onRetry: () => ref.invalidate(organizationsProvider),
                  ),
                  data: (orgs) {
                    if (orgs.isEmpty) {
                      return const AppEmptyState(
                        message: 'Cadastre uma organização antes de criar campos',
                        icon: Icons.business,
                      );
                    }
                    return KicksterDropdown<String>(
                      label: 'Organização',
                      value: _organizationId,
                      items: orgs
                          .map((o) => DropdownMenuItem(
                                value: o.id,
                                child: Text(o.tradeName),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _organizationId = value),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Selecione a organização'
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                KicksterInput(
                  label: 'Nome',
                  controller: _name,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Informe o nome'
                          : null,
                ),
                const SizedBox(height: 12),
                KicksterInput(
                  label: 'Endereço',
                  controller: _address,
                ),
                const SizedBox(height: 12),
                KicksterInput(
                  label: 'URL do mapa',
                  controller: _mapsUrl,
                  keyboardType: TextInputType.url,
                  hintText: 'Ex.: https://maps.app.goo.gl/...',
                  validator: _validateMapsUrl,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: 24),
                KicksterButton(
                  label: 'Salvar',
                  icon: Icons.check,
                  loading: _submitting,
                  onPressed: _submitting ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }
}
