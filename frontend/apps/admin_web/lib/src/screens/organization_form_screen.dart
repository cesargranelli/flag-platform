import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Formulário de criação/edição de organização.
///
/// Em edição, recebe a [Organization] via `extra`; em deep links busca por id.
class OrganizationFormScreen extends ConsumerStatefulWidget {
  const OrganizationFormScreen({super.key, this.organizationId, this.organization});

  final String? organizationId;
  final Organization? organization;

  @override
  ConsumerState<OrganizationFormScreen> createState() =>
      _OrganizationFormScreenState();
}

class _OrganizationFormScreenState extends ConsumerState<OrganizationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _legalName;
  late final TextEditingController _tradeName;
  late final TextEditingController _abbreviation;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _website;
  late final TextEditingController _instagram;
  late final TextEditingController _country;
  late final TextEditingController _state;
  late final TextEditingController _city;
  late final TextEditingController _logoUrl;
  late final TextEditingController _primaryColor;
  late final TextEditingController _secondaryColor;
  late final TextEditingController _timezone;
  late final TextEditingController _locale;

  OrganizationType? _type;
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.organizationId != null || widget.organization != null;

  @override
  void initState() {
    super.initState();
    final org = widget.organization;
    _legalName = TextEditingController(text: org?.legalName ?? '');
    _tradeName = TextEditingController(text: org?.tradeName ?? '');
    _abbreviation = TextEditingController(text: org?.abbreviation ?? '');
    _email = TextEditingController(text: org?.email ?? '');
    _phone = TextEditingController(text: org?.phone ?? '');
    _website = TextEditingController(text: org?.website ?? '');
    _instagram = TextEditingController(text: org?.instagram ?? '');
    _country = TextEditingController(text: org?.country ?? 'BR');
    _state = TextEditingController(text: org?.state ?? '');
    _city = TextEditingController(text: org?.city ?? '');
    _logoUrl = TextEditingController(text: org?.logoUrl ?? '');
    _primaryColor = TextEditingController(text: org?.primaryColor ?? '');
    _secondaryColor = TextEditingController(text: org?.secondaryColor ?? '');
    _timezone = TextEditingController(text: org?.timezone ?? 'America/Sao_Paulo');
    _locale = TextEditingController(text: org?.locale ?? 'pt-BR');
    _type = org?.organizationType;
  }

  @override
  void dispose() {
    for (final controller in [
      _legalName, _tradeName, _abbreviation, _email, _phone, _website,
      _instagram, _country, _state, _city, _logoUrl, _primaryColor,
      _secondaryColor, _timezone, _locale,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _buildBody() => {
        'legalName': _legalName.text.trim(),
        'tradeName': _tradeName.text.trim(),
        if (_abbreviation.text.trim().isNotEmpty)
          'abbreviation': _abbreviation.text.trim(),
        if (_type != null) 'organizationType': _type!.toJson(),
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
        if (_website.text.trim().isNotEmpty) 'website': _website.text.trim(),
        if (_instagram.text.trim().isNotEmpty) 'instagram': _instagram.text.trim(),
        'country': _country.text.trim().toUpperCase(),
        if (_state.text.trim().isNotEmpty) 'state': _state.text.trim(),
        if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
        if (_logoUrl.text.trim().isNotEmpty) 'logoUrl': _logoUrl.text.trim(),
        if (_primaryColor.text.trim().isNotEmpty)
          'primaryColor': _primaryColor.text.trim(),
        if (_secondaryColor.text.trim().isNotEmpty)
          'secondaryColor': _secondaryColor.text.trim(),
        'timezone': _timezone.text.trim(),
        'locale': _locale.text.trim(),
      };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(organizationApiProvider);
      final body = _buildBody();
      final id = widget.organizationId ?? widget.organization?.id;
      if (id == null) {
        await api.create(body);
      } else {
        await api.update(id, body);
      }
      ref.invalidate(organizationsProvider);
      if (mounted) context.pop();
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível salvar a organização.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgFuture = widget.organizationId != null && widget.organization == null
        ? ref.watch(organizationProvider(widget.organizationId!))
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar organização' : 'Nova organização')),
      body: orgFuture == null
          ? _buildForm(context)
          : orgFuture.when(
              loading: () => const AppLoading(message: 'Carregando organização...'),
              error: (error, stackTrace) => Center(
                child: Text('Não foi possível carregar a organização.'),
              ),
              data: (_) => _buildForm(context),
            ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field('Nome fantasia', _tradeName, 'Informe o nome fantasia'),
            const SizedBox(height: 12),
            _field('Razão social', _legalName, 'Informe a razão social'),
            const SizedBox(height: 12),
            _field('Sigla', _abbreviation),
            const SizedBox(height: 12),
            DropdownButtonFormField<OrganizationType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
              ),
              items: OrganizationType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (value) => setState(() => _type = value),
            ),
            const SizedBox(height: 12),
            _field('E-mail', _email),
            const SizedBox(height: 12),
            _field('Telefone', _phone),
            const SizedBox(height: 12),
            _field('Site', _website),
            const SizedBox(height: 12),
            _field('Instagram', _instagram),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field('País (2 letras)', _country, 'Informe o país'),
                ),
                const SizedBox(width: 12),
                Expanded(child: _field('Estado', _state)),
              ],
            ),
            const SizedBox(height: 12),
            _field('Cidade', _city),
            const SizedBox(height: 12),
            _field('URL do logo', _logoUrl),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field('Cor primária', _primaryColor)),
                const SizedBox(width: 12),
                Expanded(child: _field('Cor secundária', _secondaryColor)),
              ],
            ),
            const SizedBox(height: 12),
            _field('Timezone', _timezone, 'Informe o fuso horário'),
            const SizedBox(height: 12),
            _field('Locale', _locale, 'Informe o locale'),
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
    );
  }

  Widget _field(String label, TextEditingController controller,
      [String? validatorMessage]) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validatorMessage == null
          ? null
          : (value) => (value == null || value.trim().isEmpty)
              ? validatorMessage
              : null,
    );
  }
}
