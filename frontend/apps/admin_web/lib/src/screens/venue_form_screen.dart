import 'package:flag_api/flag_api.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

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

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(venueApiProvider);
      final id = widget.venueId ?? widget.venue?.id;
      if (id == null) {
        await api.create(
          organizationId: _organizationId!,
          name: _name.text.trim(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          mapsUrl: _mapsUrl.text.trim().isEmpty ? null : _mapsUrl.text.trim(),
        );
      } else {
        await api.update(
          id,
          organizationId: _organizationId!,
          name: _name.text.trim(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          mapsUrl: _mapsUrl.text.trim().isEmpty ? null : _mapsUrl.text.trim(),
        );
      }
      ref.invalidate(venuesProvider);
      if (mounted) context.pop();
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível salvar o campo.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final organizations = ref.watch(organizationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar campo' : 'Novo campo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              organizations.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => const Text('Erro ao carregar organizações'),
                data: (orgs) => DropdownButtonFormField<String>(
                  initialValue: _organizationId,
                  decoration: const InputDecoration(
                    labelText: 'Organização',
                    border: OutlineInputBorder(),
                  ),
                  items: orgs
                      .map((o) => DropdownMenuItem(
                            value: o.id,
                            child: Text(o.tradeName),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _organizationId = value),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Selecione a organização' : null,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Endereço',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mapsUrl,
                decoration: const InputDecoration(
                  labelText: 'URL do mapa',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _save,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
