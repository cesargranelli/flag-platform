import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Formulário de criação de organização em página única (#455): todas as
/// seções (dados básicos, presidente, contato, localização, identidade)
/// empilhadas com títulos de seção — o scroll é do body, sem barras internas.
/// A validação cobre TODAS as seções no submit.
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
  bool _submitting = false;
  bool _saved = false;
  bool _hasChanges = false;
  String? _errorMessage;

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
    if (_saved || _hasChanges) return;
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
    // Valida TODAS as seções (form único) — não por etapa.
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

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/organizations');
    }
  }

  Future<void> _handleBack() async {
    if (_hasChanges && !_submitting && !_saved) {
      final discard = await showKicksterConfirm(
        context: context,
        title: 'Descartar alterações?',
        content: 'As alterações não salvas serão perdidas.',
        confirmLabel: 'Descartar',
        cancelLabel: 'Continuar editando',
        danger: true,
      );
      if (discard != true) return;
      if (!mounted) return;
      _saved = true;
    }
    if (!mounted) return;
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
        breadcrumb: const [
          BreadcrumbItem('Início', route: '/'),
          BreadcrumbItem(AppStrings.organizations, route: '/organizations'),
          BreadcrumbItem('Nova'),
        ],
        body: AppLayout.form(
          child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) _errorBanner(_errorMessage!),
                    _section('Dados básicos', Icons.business_outlined, [
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
                _section('Presidente', Icons.person_outline, [
                  _field('Nome do presidente', _presidentName,
                      hint: 'Informe o nome do presidente',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o nome do presidente'
                          : null),
                  const SizedBox(height: 12),
                  _presidentCpfField(),
                ]),
                _section('Contato', Icons.contact_mail_outlined, [
                  _emailField(),
                  const SizedBox(height: 12),
                  _phoneField(),
                  const SizedBox(height: 12),
                  _websiteField(),
                  const SizedBox(height: 12),
                  _instagramField(),
                ]),
                _section('Localização', Icons.location_on_outlined, [
                  _countryDropdown(),
                  const SizedBox(height: 12),
                  if (_country == 'BR')
                    _stateDropdown()
                  else
                    _field('Estado (opcional)', _state),
                  const SizedBox(height: 12),
                  _field('Cidade (opcional)', _city),
                ]),
                _section('Identidade', Icons.palette_outlined, [
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
                const SizedBox(height: 8),
                KicksterButton(
                  label: 'Criar organização',
                  icon: Icons.check,
                  loading: _submitting,
                  onPressed: _submitting ? null : _save,
                ),
              ],
            ),
          ),
        ),
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

  /// Seção empilhada: título (titleMedium) + card (#455).
  Widget _section(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KicksterSectionTitle(title: title, icon: icon),
        const SizedBox(height: 12),
        _card(null, children),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _card(String? title, List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
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
                  fontWeight: FontWeight.w700,
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

  Widget _typeDropdown() {
    return KicksterDropdown<OrganizationType>(
      label: 'Tipo',
      value: _type,
      items: OrganizationType.values
          .map((t) => DropdownMenuItem(
                value: t,
                child: appDropdownItem(organizationTypeIcon(t), _typeLabel(t)),
              ))
          .toList(),
      onChanged: (value) {
        setState(() => _type = value);
        _markDirty();
      },
    );
  }

  Widget _documentField() {
    return KicksterInput(
      label: 'CNPJ (opcional)',
      controller: _document,
      keyboardType: TextInputType.number,
      hintText: '00.000.000/0000-00',
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
    return KicksterInput(
      label: 'CPF do presidente',
      controller: _presidentCpf,
      keyboardType: TextInputType.number,
      hintText: '000.000.000-00',
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
    return KicksterInput(
      label: 'E-mail (opcional)',
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      hintText: 'contato@exemplo.com',
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
            ? null
            : 'E-mail inválido';
      },
    );
  }

  Widget _phoneField() {
    return KicksterInput(
      label: 'Telefone (opcional)',
      controller: _phone,
      keyboardType: TextInputType.phone,
      hintText: '(11) 99999-9999',
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
    return KicksterInput(
      label: 'Site (opcional)',
      controller: _website,
      keyboardType: TextInputType.url,
      hintText: 'https://exemplo.com.br',
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
    return KicksterInput(
      label: 'Instagram (opcional)',
      controller: _instagram,
      hintText: '@meuclube',
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
    return KicksterDropdown<String>(
      label: 'País',
      value: _country,
      values: [for (final c in _countryOptions) c.code],
      labels: [for (final c in _countryOptions) c.name],
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
    return KicksterDropdown<String>(
      label: 'Estado',
      hint: 'Selecione o estado',
      value: _state.text.isEmpty ? null : _state.text,
      values: [for (final uf in _ufs) uf.$1],
      labels: [for (final uf in _ufs) '${uf.$2} (${uf.$1})'],
      onChanged: (value) {
        setState(() {
          _state.text = value ?? '';
        });
        _markDirty();
      },
    );
  }

  Widget _logoField() {
    return KicksterInput(
      label: 'URL do logo (opcional)',
      controller: _logoUrl,
      keyboardType: TextInputType.url,
      hintText: 'https://exemplo.com/logo.png',
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
      child: KicksterInput(
        label: label,
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
        hintText: '#FD6B22',
        prefix: IconButton(
          tooltip: 'Escolher cor',
          onPressed: () => _openColorPicker(controller),
          icon: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _parseHex(controller.text) ?? AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line),
            ),
          ),
        ),
      ),
    );
  }

  Widget _localeDropdown() {
    return KicksterDropdown<String>(
      label: 'Idioma',
      value: _locale.text,
      values: [for (final l in _localeOptions) l.code],
      labels: [for (final l in _localeOptions) l.name],
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
            fontWeight: FontWeight.w700,
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
                    errorBuilder: (_, _, _) => Icon(
                      organizationTypeIcon(_type),
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                )
              else
                Icon(organizationTypeIcon(_type),
                    color: Colors.white, size: 40),
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
                        fontWeight: FontWeight.w700,
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
    return KicksterInput(
      label: label,
      controller: controller,
      keyboardType: keyboardType,
      hintText: hint,
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
            KicksterInput(
              label: 'Código hex',
              controller: _hex,
              hintText: 'FD6B22',
              prefix: const Text('#'),
              suffixIcon: const Icon(Icons.circle, color: AppColors.line),
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
        KicksterButton(
          label: 'Cancelar',
          variant: KicksterButtonVariant.text,
          onPressed: () => Navigator.pop(context),
        ),
        KicksterButton(
          label: 'Aplicar',
          onPressed: () {
            final hex = _hex.text.trim();
            Navigator.pop(context, '#${hex.toUpperCase()}');
          },
        ),
      ],
    );
  }
}