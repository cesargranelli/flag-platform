import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Formulário de criação/edição de organização em etapas (wizard).
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

  late final TextEditingController _tradeName;
  late final TextEditingController _legalName;
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
  int _step = 0;
  bool _submitting = false;
  String? _errorMessage;

  static const _titles = ['Identificação', 'Contato', 'Visual'];

  bool get _isEditing => widget.organizationId != null || widget.organization != null;

  @override
  void initState() {
    super.initState();
    final org = widget.organization;
    _tradeName = TextEditingController(text: org?.tradeName ?? '');
    _legalName = TextEditingController(text: org?.legalName ?? '');
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
      _tradeName, _legalName, _abbreviation, _email, _phone, _website,
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

  bool _validateStep(int step) {
    if (step == 0) {
      return _formKey.currentState!.validate();
    }
    return true;
  }

  void _next() {
    if (_validateStep(_step)) {
      if (_step < 2) {
        setState(() => _step += 1);
      } else {
        _save();
      }
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
          ? _buildWizard(context)
          : orgFuture.when(
              loading: () => const AppLoading(message: 'Carregando organização...'),
              error: (error, stackTrace) =>
                  const Center(child: Text('Não foi possível carregar a organização.')),
              data: (_) => _buildWizard(context),
            ),
    );
  }

  Widget _buildWizard(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                for (var i = 0; i < _titles.length; i++)
                  Expanded(
                    child: _stepIndicator(i),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _stepContent(context, _step),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _step > 0 ? () => setState(() => _step -= 1) : null,
                  child: const Text('Voltar'),
                ),
                FilledButton(
                  onPressed: _submitting ? null : _next,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_step == 2 ? 'Salvar' : 'Continuar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepIndicator(int index) {
    final selected = index == _step;
    final done = index < _step;
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: selected
              ? Theme.of(context).colorScheme.primary
              : done
                  ? AppColors.success
                  : AppColors.textSecondary.withValues(alpha: 0.3),
          child: done
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          _titles[index],
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _stepContent(BuildContext context, int step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (step == 0) ...[
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
        ] else if (step == 1) ...[
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
              Expanded(child: _field('País (2 letras)', _country, 'Informe o país')),
              const SizedBox(width: 12),
              Expanded(child: _field('Estado', _state)),
            ],
          ),
          const SizedBox(height: 12),
          _field('Cidade', _city),
        ] else ...[
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
        ],
      ],
    );
  }

  Widget _field(String label, TextEditingController controller, [String? validatorMessage]) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validatorMessage == null
          ? null
          : (value) => (value == null || value.trim().isEmpty) ? validatorMessage : null,
    );
  }
}
