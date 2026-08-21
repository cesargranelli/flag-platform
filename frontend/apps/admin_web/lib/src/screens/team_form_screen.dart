import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_back_button.dart';

/// Formulário de criação/edição de time.
class TeamFormScreen extends ConsumerStatefulWidget {
  const TeamFormScreen({super.key, this.teamId, this.team});

  final String? teamId;
  final Team? team;

  @override
  ConsumerState<TeamFormScreen> createState() => _TeamFormScreenState();
}

class _TeamFormScreenState extends ConsumerState<TeamFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _shortName;
  late final TextEditingController _document;
  late final TextEditingController _logoUrl;
  String? _competitionId;
  String? _divisionId;
  DocumentType? _documentType;
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.teamId != null || widget.team != null;

  @override
  void initState() {
    super.initState();
    final team = widget.team;
    _name = TextEditingController(text: team?.name ?? '');
    _shortName = TextEditingController(text: team?.shortName ?? '');
    _document = TextEditingController(text: team?.document ?? '');
    _logoUrl = TextEditingController(text: team?.logoUrl ?? '');
    _competitionId = widget.team?.competitionId;
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
      if (id == null) {
        await api.create(
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
      } else {
        await api.update(
          id,
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
      }
      ref.invalidate(teamsProvider);
      if (mounted) {
        if (id != null) {
          ref.invalidate(teamProvider(id));
          context.go('/teams/$id');
        } else {
          context.pop();
        }
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
    final compItems = competitions.valueOrNull ?? const [];
    final effectiveComp =
        _competitionId ??
        ref.watch(selectedCompetitionProvider) ??
        (compItems.isNotEmpty ? compItems.first.id : null);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar time' : 'Novo time'),
        leading: AppBackButton(fallbackRoute: '/teams'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppLayout.form(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: effectiveComp,
                  decoration: const InputDecoration(
                    labelText: 'Campeonato',
                    border: OutlineInputBorder(),
                  ),
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
                TextFormField(
                  controller: _name,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Informe o nome'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _shortName,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'Sigla',
                    helperText: 'Ex.: FLA',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DocumentType>(
                  initialValue: _documentType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de documento',
                    border: OutlineInputBorder(),
                  ),
                  items: DocumentType.values
                      .map(
                        (d) => DropdownMenuItem(value: d, child: Text(d.label)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _documentType = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _document,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'CNPJ do time ou CPF do representante',
                    hintText: _documentType == DocumentType.cpf
                        ? '000.000.000-00'
                        : '00.000.000/0000-00',
                    border: const OutlineInputBorder(),
                  ),
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
                TextFormField(
                  controller: _logoUrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL do logo',
                    helperText: 'Ex.: https://...',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateLogoUrl,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
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
      ),
    );
  }
}
