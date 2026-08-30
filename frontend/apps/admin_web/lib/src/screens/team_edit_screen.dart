import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Formulário de edição de time.
class TeamEditScreen extends ConsumerStatefulWidget {
  const TeamEditScreen({super.key, this.teamId, this.team});

  final String? teamId;
  final Team? team;

  @override
  ConsumerState<TeamEditScreen> createState() => _TeamEditScreenState();
}

class _TeamEditScreenState extends ConsumerState<TeamEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _shortName;
  late final TextEditingController _document;
  late final TextEditingController _logoUrl;
  String? _organizationId;
  String? _competitionId;
  String? _divisionId;
  DocumentType? _documentType;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final team = widget.team;
    _name = TextEditingController(text: team?.name ?? '');
    _shortName = TextEditingController(text: team?.shortName ?? '');
    _document = TextEditingController(text: team?.document ?? '');
    _logoUrl = TextEditingController(text: team?.logoUrl ?? '');
    _competitionId = widget.team?.competitionId;
    _organizationId = team?.organizationId;
    _divisionId = team?.divisionId;
    _documentType = team?.documentType;
  }

  @override
  void dispose() {
    _name.dispose();
    _shortName.dispose();
    _document.dispose();
    _logoUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(teamApiProvider);
      final id = widget.teamId ?? widget.team?.id;
      // organizationId é obrigatório no backend (@NotNull) e o validador do
      // dropdown garante que esteja preenchido.
      await api.update(
        id!,
        organizationId: _organizationId!,
        competitionId: _competitionId ?? '',
        divisionId: _divisionId,
        name: _name.text.trim(),
        shortName: _shortName.text.trim().isEmpty
            ? null
            : _shortName.text.trim(),
        document: _document.text.trim().isEmpty
            ? null
            : _document.text.trim().replaceAll(RegExp(r'\D'), ''),
        documentType: _documentType,
        logoUrl: _logoUrl.text.trim().isEmpty ? null : _logoUrl.text.trim(),
      );
      ref.invalidate(teamsProvider(_competitionId ?? ''));
      if (mounted) {
        ref.invalidate(teamProvider(id));
        context.go('/teams/$id');
      }
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível salvar o time.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _validateLogoUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    final valid =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return valid ? null : 'Informe uma URL válida (http/https)';
  }

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);
    final organizations = ref.watch(organizationsProvider);
    final compItems = competitions.valueOrNull ?? const [];
    // P4 #461: _competitionId (contexto) ?? efetivo (selecionado ?? primeiro).
    final effectiveComp =
        _competitionId ?? ref.watch(effectiveCompetitionProvider);

    return AppScreen(
      title: 'Editar time',
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem(AppStrings.teams, route: '/teams'),
        BreadcrumbItem('Editar'),
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
                  error: (e, s) => const Text('Erro ao carregar organizações'),
                  data: (orgs) {
                    // Ao editar, a organização atual pode não estar na lista
                    // (ex.: desativada); mantém como opção para o dropdown
                    // pré-selecionar sem quebrar.
                    final items = orgs
                        .map(
                          (o) => DropdownMenuItem(
                            value: o.id,
                            child: Text(o.tradeName),
                          ),
                        )
                        .toList();
                    final currentId = _organizationId;
                    if (currentId != null &&
                        currentId.isNotEmpty &&
                        !orgs.any((o) => o.id == currentId)) {
                      items.insert(
                        0,
                        DropdownMenuItem(
                          value: currentId,
                          child: const Text('Organização atual (indisponível)'),
                        ),
                      );
                    }
                    return KicksterDropdown<String>(
                      label: 'Organização (clube)',
                      value: _organizationId,
                      items: items,
                      onChanged: (value) =>
                          setState(() => _organizationId = value),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Selecione a organização'
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                KicksterDropdown<String>(
                  label: 'Campeonato',
                  value: effectiveComp,
                  items: compItems
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _competitionId = value);
                    ref.read(selectedCompetitionProvider.notifier).state =
                        value;
                  },
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Selecione o campeonato'
                      : null,
                ),
                const SizedBox(height: 12),
                KicksterInput(
                  label: 'Nome',
                  controller: _name,
                  maxLength: 100,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Informe o nome'
                          : null,
                ),
                const SizedBox(height: 12),
                KicksterInput(
                  label: 'Sigla',
                  controller: _shortName,
                  maxLength: 10,
                  hintText: 'Ex.: FLA',
                ),
                const SizedBox(height: 12),
                KicksterDropdown<DocumentType>(
                  label: 'Tipo de documento',
                  value: _documentType,
                  items: DocumentType.values
                      .map(
                        (d) => DropdownMenuItem(value: d, child: Text(d.label)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _documentType = value),
                ),
                const SizedBox(height: 12),
                KicksterInput(
                  label: 'CNPJ do time ou CPF do representante',
                  controller: _document,
                  keyboardType: TextInputType.number,
                  hintText: _documentType == DocumentType.cpf
                      ? '000.000.000-00'
                      : '00.000.000/0000-00',
                  onChanged: (value) {
                    final masked = _documentType == DocumentType.cpf
                        ? DocumentUtils.maskCpf(value)
                        : DocumentUtils.maskCnpj(value);
                    if (masked != value) {
                      _document.value = TextEditingValue(
                        text: masked,
                        selection: TextSelection.collapsed(
                          offset: masked.length,
                        ),
                      );
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o CNPJ do time ou o CPF do representante';
                    }
                    final type = _documentType ?? DocumentType.cnpj;
                    final valid = type == DocumentType.cpf
                        ? DocumentUtils.isValidCpf(value)
                        : DocumentUtils.isValidCnpj(value);
                    return valid ? null : 'Documento inválido';
                  },
                ),
                const SizedBox(height: 12),
                KicksterInput(
                  label: 'URL do logo',
                  controller: _logoUrl,
                  keyboardType: TextInputType.url,
                  hintText: 'Ex.: https://...',
                  validator: _validateLogoUrl,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
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
