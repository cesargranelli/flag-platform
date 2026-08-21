import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_back_button.dart';

/// Argumentos de navegação do formulário de divisão.
class DivisionFormArgs {
  const DivisionFormArgs({this.competitionId, this.conferenceId});

  final String? competitionId;
  final String? conferenceId;
}

/// Formulário de criação/edição de divisão.
class DivisionFormScreen extends ConsumerStatefulWidget {
  const DivisionFormScreen({
    super.key,
    this.divisionId,
    this.division,
    this.args,
  });

  final String? divisionId;
  final Division? division;
  final DivisionFormArgs? args;

  @override
  ConsumerState<DivisionFormScreen> createState() => _DivisionFormScreenState();
}

class _DivisionFormScreenState extends ConsumerState<DivisionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  String? _competitionId;
  String? _conferenceId;
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.divisionId != null || widget.division != null;

  @override
  void initState() {
    super.initState();
    final division = widget.division;
    _name = TextEditingController(text: division?.name ?? '');
    _competitionId = widget.args?.competitionId;
    _conferenceId = widget.args?.conferenceId;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final competitionId =
        _competitionId ?? ref.read(selectedCompetitionProvider);
    final conferenceId = _conferenceId;

    if (competitionId == null || competitionId.isEmpty) {
      setState(() => _errorMessage = 'Concurso não informado.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(divisionApiProvider);
      final id = widget.divisionId ?? widget.division?.id;
      if (id == null) {
        await api.create(
          competitionId: competitionId,
          conferenceId: conferenceId,
          name: _name.text.trim(),
        );
      } else {
        await api.update(
          id,
          competitionId: competitionId,
          conferenceId: conferenceId,
          name: _name.text.trim(),
        );
      }
      ref.invalidate(competitionsProvider);
      if (mounted) context.pop();
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível salvar a divisão.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
        title: Text(_isEditing ? 'Editar divisão' : 'Nova divisão'),
        leading: AppBackButton(fallbackRoute: '/groupings'),
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
