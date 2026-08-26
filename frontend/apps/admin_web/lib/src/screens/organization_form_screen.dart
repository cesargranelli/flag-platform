import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Formulário de criação de organização em etapas (wizard).
///
/// V250: organizações não são editáveis após a criação — este formulário
/// apenas cria. Alterações de cadastro não são suportadas.
class OrganizationFormScreen extends ConsumerStatefulWidget {
  const OrganizationFormScreen({super.key});

  @override
  ConsumerState<OrganizationFormScreen> createState() =>
      _OrganizationFormScreenState();
}

class _OrganizationFormScreenState extends ConsumerState<OrganizationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tradeName;
  late final TextEditingController _legalName;
  late final TextEditingController _abbreviation;
  late final TextEditingController _document;
  late final TextEditingController _presidentName;
  late final TextEditingController _presidentCpf;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _website;
  late final TextEditingController _instagram;
  late final TextEditingController _state;
  late final TextEditingController _city;
  late final TextEditingController _logoUrl;
  late final TextEditingController _primaryColor;
  late final TextEditingController _secondaryColor;
  late final TextEditingController _tertiaryColor;
  late final TextEditingController _quaternaryColor;
  late final TextEditingController _locale;

  String _country = 'BR';
  final _timezone = 'America/Sao_Paulo'; // fixo; removido da UI

  OrganizationType? _type;
  DocumentType? _documentType;
  int _step = 0;
  bool _submitting = false;
  bool _saved = false;
  bool _hasChanges = false;
  String? _errorMessage;

  static const _titles = [
    'Identificação',
    'Presidente',
    'Contato',
    'Localização',
    'Identidade',
  ];

  @override
  void initState() {
    super.initState();
    // Formulário apenas de criação: todos os campos iniciam vazios.
    _tradeName = TextEditingController();
    _legalName = TextEditingController();
    _abbreviation = TextEditingController();
    _document = TextEditingController();
    _presidentName = TextEditingController();
    _presidentCpf = TextEditingController();
    _email = TextEditingController();
    _phone = TextEditingController();
    _website = TextEditingController();
    _instagram = TextEditingController();
    _state = TextEditingController();
    _city = TextEditingController();
    _logoUrl = TextEditingController();
    _primaryColor = TextEditingController();
    _secondaryColor = TextEditingController();
    _tertiaryColor = TextEditingController();
    _quaternaryColor = TextEditingController();
    _locale = TextEditingController(text: 'pt-BR');
    _country = 'BR';
    _type = null;
    _documentType = DocumentType.cnpj;

    for (final controller in [
      _tradeName, _legalName, _abbreviation, _document, _presidentName,
      _presidentCpf, _email, _phone, _website, _instagram, _state, _city,
      _logoUrl, _primaryColor, _secondaryColor, _tertiaryColor,
      _quaternaryColor, _locale,
    ]) {
      controller.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (_saved) return;
    setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    for (final controller in [
      _tradeName, _legalName, _abbreviation, _document, _presidentName,
      _presidentCpf, _email, _phone, _website, _instagram, _state, _city,
      _logoUrl, _primaryColor, _secondaryColor, _tertiaryColor,
      _quaternaryColor, _locale,
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
        if (_document.text.trim().isNotEmpty)
          'document': _document.text.trim().replaceAll(RegExp(r'\D'), ''),
        if (_documentType != null) 'documentType': _documentType!.toJson(),
        if (_presidentName.text.trim().isNotEmpty)
          'presidentName': _presidentName.text.trim(),
        if (_presidentCpf.text.trim().isNotEmpty)
          'presidentCpf': _presidentCpf.text.trim().replaceAll(RegExp(r'\D'), ''),
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
        if (_website.text.trim().isNotEmpty) 'website': _website.text.trim(),
        if (_instagram.text.trim().isNotEmpty)
          'instagram': _instagram.text.trim(),
        'country': _country,
        if (_state.text.trim().isNotEmpty) 'state': _state.text.trim(),
        if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
        if (_logoUrl.text.trim().isNotEmpty) 'logoUrl': _logoUrl.text.trim(),
        if (_primaryColor.text.trim().isNotEmpty)
          'primaryColor': _primaryColor.text.trim(),
        if (_secondaryColor.text.trim().isNotEmpty)
          'secondaryColor': _secondaryColor.text.trim(),
        if (_tertiaryColor.text.trim().isNotEmpty)
          'tertiaryColor': _tertiaryColor.text.trim(),
        if (_quaternaryColor.text.trim().isNotEmpty)
          'quaternaryColor': _quaternaryColor.text.trim(),
        'timezone': _timezone,
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
      // V250: organizações não são editáveis — o form apenas cria.
      final created = await api.create(body);
      _saved = true;
      ref.invalidate(organizationsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organização salva com sucesso')),
      );
      // Vai para o detalhe da organização recém-criada.
      context.go('/organizations/${created.id}');
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível salvar a organização.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool _validateStep() {
    return _formKey.currentState!.validate();
  }

  void _next() {
    if (_validateStep()) {
      if (_step < _titles.length - 1) {
        setState(() => _step += 1);
      } else {
        _save();
      }
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/organizations');
    }
  }

  Future<void> _handleBack() async {
    if (_hasChanges && !_submitting && !_saved) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Descartar alterações?'),
          content: const Text('As alterações não salvas serão perdidas.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Continuar editando'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
      if (discard != true) return;
      _saved = true;
    }
    _goBack();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges || _submitting || _saved,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: AppScreen(
        title: 'Nova organização',
        leading: BackButton(onPressed: _handleBack),
        body: _buildWizard(context),
      ),
    );
  }

  Widget _buildWizard(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: AppLayout.form(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: AppSessionNav(
                      sessions: _titles,
                      activeIndex: _step,
                      showDoneState: true,
                      onTap: _handleStepTap,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_errorMessage != null)
                            _errorBanner(_errorMessage!),
                          _stepContent(context, _step),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppLayout.form(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _submitting
                        ? null
                        : () {
                            if (_step == 0) {
                              _handleBack();
                            } else {
                              setState(() => _step -= 1);
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(120, 56),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    icon: Icon(_step == 0 ? Icons.close : Icons.arrow_back),
                    label: Text(_step == 0 ? 'Cancelar' : 'Voltar'),
                  ),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _next,
                    icon: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: Text(_step == _titles.length - 1 ? 'Salvar' : 'Continuar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  /// Tocar em uma etapa do indicador: avança apenas sequencialmente (com
  /// validação da etapa atual) e volta livremente (#323).
  void _handleStepTap(int index) {
    if (index == _step) return;
    // Só permite avançar um passo por vez, validando o passo atual
    // antes (os passos intermediários só são validados na sequência).
    if (index > _step) {
      if (index > _step + 1) return;
      if (!_validateStep()) return;
    }
    setState(() => _step = index);
  }

  Widget _card(String? title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
            ],
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _stepContent(BuildContext context, int step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (step == 0) ...[
          _card('Dados básicos', [
            _field('Nome fantasia', _tradeName,
                hint: 'Informe o nome fantasia',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o nome fantasia'
                    : null),
            const SizedBox(height: 12),
            _field('Razão social', _legalName,
                hint: 'Informe a razão social',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe a razão social'
                    : null),
            const SizedBox(height: 12),
            _field('Sigla (opcional)', _abbreviation),
            const SizedBox(height: 12),
            _typeDropdown(),
            const SizedBox(height: 12),
            _documentField(),
          ]),
        ] else if (step == 1) ...[
          _card('Presidente', [
            _field('Nome do presidente', _presidentName,
                hint: 'Informe o nome do presidente',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o nome do presidente'
                    : null),
            const SizedBox(height: 12),
            _presidentCpfField(),
          ]),
        ] else if (step == 2) ...[
          _card('Contato', [
            _emailField(),
            const SizedBox(height: 12),
            _phoneField(),
            const SizedBox(height: 12),
            _websiteField(),
            const SizedBox(height: 12),
            _instagramField(),
          ]),
        ] else if (step == 3) ...[
          _card('Localização', [
            _countryDropdown(),
            const SizedBox(height: 12),
            if (_country == 'BR')
              _stateDropdown()
            else
              _field('Estado (opcional)', _state),
            const SizedBox(height: 12),
            _field('Cidade (opcional)', _city),
          ]),
        ] else ...[
          _card(null, [
            _brandPreview(),
            const SizedBox(height: 16),
            _logoField(),
            const SizedBox(height: 12),
            Row(
              children: [
                _colorField('Cor primária (opcional)', _primaryColor),
                const SizedBox(width: 12),
                _colorField('Cor secundária (opcional)', _secondaryColor),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _colorField('Cor terciária (opcional)', _tertiaryColor),
                const SizedBox(width: 12),
                _colorField('Cor quaternária (opcional)', _quaternaryColor),
              ],
            ),
            const SizedBox(height: 12),
            _localeDropdown(),
          ]),
        ],
      ],
    );
  }

  Widget _typeDropdown() {
    return DropdownButtonFormField<OrganizationType>(
      initialValue: _type,
      decoration: const InputDecoration(labelText: 'Tipo'),
      items: OrganizationType.values
          .map((t) =>
              DropdownMenuItem(value: t, child: Text(_typeLabel(t))))
          .toList(),
      onChanged: (value) {
        setState(() => _type = value);
        _markDirty();
      },
    );
  }

  Widget _documentField() {
    return TextFormField(
      controller: _document,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'CNPJ (opcional)',
        hintText: '00.000.000/0000-00',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        final masked = DocumentUtils.maskCnpj(value);
        if (masked != value) {
          _document.value = TextEditingValue(
            text: masked,
            selection: TextSelection.collapsed(offset: masked.length),
          );
        }
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null; // opcional
        return DocumentUtils.isValidCnpj(value) ? null : 'Documento inválido';
      },
    );
  }

  Widget _presidentCpfField() {
    return TextFormField(
      controller: _presidentCpf,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'CPF do presidente',
        hintText: '000.000.000-00',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        final masked = DocumentUtils.maskCpf(value);
        if (masked != value) {
          _presidentCpf.value = TextEditingValue(
            text: masked,
            selection: TextSelection.collapsed(offset: masked.length),
          );
        }
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Informe o CPF do presidente';
        return DocumentUtils.isValidCpf(value) ? null : 'CPF inválido';
      },
    );
  }

  Widget _emailField() {
    return TextFormField(
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'E-mail (opcional)',
        hintText: 'contato@exemplo.com',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
            ? null
            : 'E-mail inválido';
      },
    );
  }

  Widget _phoneField() {
    return TextFormField(
      controller: _phone,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(
        labelText: 'Telefone (opcional)',
        hintText: '(11) 99999-9999',
      ),
      onChanged: (value) {
        final masked = _maskPhone(value);
        if (masked != value) {
          _phone.value = TextEditingValue(
            text: masked,
            selection: TextSelection.collapsed(offset: masked.length),
          );
        }
      },
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final digits = v.replaceAll(RegExp(r'\D'), '');
        return (digits.length == 10 || digits.length == 11)
            ? null
            : 'Telefone inválido';
      },
    );
  }

  Widget _websiteField() {
    return TextFormField(
      controller: _website,
      keyboardType: TextInputType.url,
      decoration: const InputDecoration(
        labelText: 'Site (opcional)',
        hintText: 'https://exemplo.com.br',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final t = v.trim();
        final uri =
            Uri.tryParse(t.startsWith('http') ? t : 'https://$t');
        return (uri != null &&
                (uri.scheme == 'http' || uri.scheme == 'https') &&
                uri.host.isNotEmpty)
            ? null
            : 'URL inválida';
      },
    );
  }

  Widget _instagramField() {
    return TextFormField(
      controller: _instagram,
      decoration: const InputDecoration(
        labelText: 'Instagram (opcional)',
        hintText: '@meuclube',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final t = v.trim().replaceFirst('@', '');
        return RegExp(r'^[A-Za-z0-9_.]{1,30}$').hasMatch(t)
            ? null
            : 'Usuário inválido';
      },
    );
  }

  Widget _countryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _country,
      decoration: const InputDecoration(labelText: 'País'),
      items: [
        for (final c in _countryOptions)
          DropdownMenuItem(value: c.code, child: Text(c.name)),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _country = value;
          _state.clear();
        });
        _markDirty();
      },
    );
  }

  Widget _stateDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _state.text.isEmpty ? null : _state.text,
      decoration: const InputDecoration(
        labelText: 'Estado',
        hintText: 'Selecione o estado',
      ),
      items: [
        for (final uf in _ufs)
          DropdownMenuItem(
              value: uf.$1, child: Text('${uf.$2} (${uf.$1})')),
      ],
      onChanged: (value) {
        setState(() {
          _state.text = value ?? '';
        });
        _markDirty();
      },
    );
  }

  Widget _logoField() {
    return TextFormField(
      controller: _logoUrl,
      keyboardType: TextInputType.url,
      decoration: const InputDecoration(
        labelText: 'URL do logo (opcional)',
        hintText: 'https://exemplo.com/logo.png',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final uri = Uri.tryParse(v.trim());
        return (uri != null &&
                (uri.scheme == 'http' || uri.scheme == 'https') &&
                uri.host.isNotEmpty)
            ? null
            : 'URL inválida';
      },
    );
  }

  Widget _colorField(String label, TextEditingController controller) {
    return Expanded(
      child: TextFormField(
        controller: controller,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
          LengthLimitingTextInputFormatter(7),
        ],
        onChanged: (v) {
          final t = v.toUpperCase();
          if (t != v) {
            controller.value = TextEditingValue(
              text: t,
              selection: TextSelection.collapsed(offset: t.length),
            );
          }
        },
        validator: (v) {
          if (v == null || v.trim().isEmpty) return null;
          return RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(v.trim())
              ? null
              : 'Use #RRGGBB';
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: '#FD6B22',
          prefixIcon: IconButton(
            tooltip: 'Escolher cor',
            onPressed: () => _openColorPicker(controller),
            icon: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _parseHex(controller.text) ?? AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _localeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _locale.text,
      decoration: const InputDecoration(labelText: 'Idioma'),
      items: [
        for (final l in _localeOptions)
          DropdownMenuItem(value: l.code, child: Text(l.name)),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => _locale.text = value);
        _markDirty();
      },
    );
  }

  Widget _brandPreview() {
    final primary = _parseHex(_primaryColor.text) ?? AppColors.primary;
    final secondary = _parseHex(_secondaryColor.text) ?? AppColors.secondary;
    final tertiary = _parseHex(_tertiaryColor.text);
    final quaternary = _parseHex(_quaternaryColor.text);
    final logo = _logoUrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prévia da marca',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (logo.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    logo,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.business,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                )
              else
                const Icon(Icons.business, color: Colors.white, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tradeName.text.isEmpty
                          ? 'Nome da organização'
                          : _tradeName.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 80,
                      height: 6,
                      decoration: BoxDecoration(
                        color: secondary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Paleta completa (até 4 cores) quando terciária/quaternária definidas.
        if (tertiary != null || quaternary != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _previewSwatch(primary),
              _previewSwatch(secondary),
              if (tertiary != null) _previewSwatch(tertiary),
              if (quaternary != null) _previewSwatch(quaternary),
            ],
          ),
        ],
      ],
    );
  }

  Widget _previewSwatch(Color color) {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.textSecondary, width: 0.5),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: validator,
    );
  }

  Future<void> _openColorPicker(TextEditingController controller) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => _ColorPickerDialog(initial: controller.text),
    );
    if (picked != null) {
      setState(() => controller.text = picked);
    }
  }

  static const _ufs = <(String, String)>[
    ('AC', 'Acre'), ('AL', 'Alagoas'), ('AP', 'Amapá'), ('AM', 'Amazonas'),
    ('BA', 'Bahia'), ('CE', 'Ceará'), ('DF', 'Distrito Federal'),
    ('ES', 'Espírito Santo'), ('GO', 'Goiás'), ('MA', 'Maranhão'),
    ('MT', 'Mato Grosso'), ('MS', 'Mato Grosso do Sul'), ('MG', 'Minas Gerais'),
    ('PA', 'Pará'), ('PB', 'Paraíba'), ('PR', 'Paraná'),
    ('PE', 'Pernambuco'), ('PI', 'Piauí'), ('RJ', 'Rio de Janeiro'),
    ('RN', 'Rio Grande do Norte'), ('RS', 'Rio Grande do Sul'),
    ('RO', 'Rondônia'), ('RR', 'Roraima'), ('SC', 'Santa Catarina'),
    ('SP', 'São Paulo'), ('SE', 'Sergipe'), ('TO', 'Tocantins'),
  ];

  static const _countries = <_Option>[
    _Option('Brasil', 'BR'),
    _Option('Argentina', 'AR'),
    _Option('Estados Unidos', 'US'),
    _Option('Portugal', 'PT'),
    _Option('Espanha', 'ES'),
    _Option('França', 'FR'),
    _Option('Alemanha', 'DE'),
    _Option('Reino Unido', 'GB'),
    _Option('Itália', 'IT'),
    _Option('Canadá', 'CA'),
    _Option('México', 'MX'),
    _Option('Colômbia', 'CO'),
    _Option('Chile', 'CL'),
    _Option('Peru', 'PE'),
    _Option('Uruguai', 'UY'),
    _Option('Paraguai', 'PY'),
    _Option('Japão', 'JP'),
    _Option('Austrália', 'AU'),
  ];

  static const _locales = <_Option>[
    _Option('Português (Brasil)', 'pt-BR'),
    _Option('English (US)', 'en-US'),
    _Option('Español', 'es-ES'),
  ];

  List<_Option> get _countryOptions {
    final options = [..._countries];
    if (_country.isNotEmpty && !options.any((o) => o.code == _country)) {
      options.insert(0, _Option(_country, _country));
    }
    return options;
  }

  List<_Option> get _localeOptions {
    final options = [..._locales];
    if (!options.any((o) => o.code == _locale.text)) {
      options.insert(0, _Option(_locale.text, _locale.text));
    }
    return options;
  }

  String _typeLabel(OrganizationType t) => switch (t) {
        OrganizationType.federation => 'Federação',
        OrganizationType.league => 'Liga',
        OrganizationType.association => 'Associação',
        OrganizationType.university => 'Universidade',
        OrganizationType.club => 'Clube',
        OrganizationType.other => 'Outro',
      };

  String _maskPhone(String value) {
    final d = value.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '';
    if (d.length <= 2) return d;
    if (d.length <= 7) return '(${d.substring(0, 2)}) ${d.substring(2)}';
    if (d.length <= 11) {
      return '(${d.substring(0, 2)}) ${d.substring(2, d.length - 4)}-'
          '${d.substring(d.length - 4)}';
    }
    return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-'
        '${d.substring(7, 11)}';
  }
}

Color? _parseHex(String hex) {
  final h = hex.trim().replaceAll('#', '');
  if (h.length != 6) return null;
  final value = int.tryParse(h, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

class _Option {
  const _Option(this.name, this.code);
  final String name;
  final String code;
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({this.initial});

  final String? initial;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late final TextEditingController _hex;

  static const _presets = <String>[
    '#FD6B22', '#F15223', '#FF6628', '#4FBF67', '#F04C4C', '#040415',
    '#1B1D21', '#737373', '#4C9AFF', '#7C5CFF', '#2EC4B6', '#FFD166',
    '#EF476F', '#06D6A0', '#FFFFFF', '#000000',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial ?? '';
    _hex = TextEditingController(text: initial.replaceAll('#', ''));
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _apply(String hex) {
    setState(() {
      _hex.text = hex.replaceAll('#', '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final preview = _parseHex('#${_hex.text}') ?? Colors.transparent;
    return AlertDialog(
      title: const Text('Escolher cor'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _hex,
              decoration: const InputDecoration(
                labelText: 'Código hex',
                hintText: 'FD6B22',
                prefixText: '#',
                suffixIcon: Icon(Icons.circle, color: Colors.black26),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: preview,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.black, width: 1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '#${_hex.text.toUpperCase()}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hex in _presets)
                  InkWell(
                    onTap: () => _apply(hex),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _parseHex(hex) ?? Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.black, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final hex = _hex.text.trim();
            Navigator.pop(context, '#${hex.toUpperCase()}');
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}