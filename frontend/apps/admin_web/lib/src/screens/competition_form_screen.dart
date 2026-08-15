import 'package:flag_api/flag_api.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Formulário de criação/edição de campeonato.
class CompetitionFormScreen extends ConsumerStatefulWidget {
  const CompetitionFormScreen({super.key, this.competitionId, this.competition});

  final String? competitionId;
  final Competition? competition;

  @override
  ConsumerState<CompetitionFormScreen> createState() =>
      _CompetitionFormScreenState();
}

class _CompetitionFormScreenState extends ConsumerState<CompetitionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _organizationId;
  late final TextEditingController _startDate;
  late final TextEditingController _endDate;

  CompetitionStatus? _status;
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.competitionId != null || widget.competition != null;

  @override
  void initState() {
    super.initState();
    final competition = widget.competition;
    _name = TextEditingController(text: competition?.name ?? '');
    _description = TextEditingController(text: competition?.description ?? '');
    _organizationId = TextEditingController(text: competition?.organizationId ?? '');
    _startDate = TextEditingController(text: _formatDate(competition?.startDate));
    _endDate = TextEditingController(text: _formatDate(competition?.endDate));
    _status = competition?.status;
  }

  @override
  void dispose() {
    for (final controller in [
      _name, _description, _organizationId, _startDate, _endDate,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = _formatDate(picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(competitionApiProvider);
      final args = (
        organizationId: _organizationId.text.trim(),
        name: _name.text.trim(),
        description: _description.text.trim(),
        startDate: _startDate.text.isEmpty ? null : _startDate.text,
        endDate: _endDate.text.isEmpty ? null : _endDate.text,
        status: _status,
      );
      final id = widget.competitionId ?? widget.competition?.id;
      if (id == null) {
        await api.create(
          organizationId: args.organizationId,
          name: args.name,
          description: args.description,
          startDate: args.startDate,
          endDate: args.endDate,
          status: args.status,
        );
      } else {
        await api.update(
          id,
          organizationId: args.organizationId,
          name: args.name,
          description: args.description,
          startDate: args.startDate,
          endDate: args.endDate,
          status: args.status,
        );
      }
      ref.invalidate(competitionsProvider);
      if (mounted) context.pop();
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível salvar o campeonato.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final organizations = ref.watch(organizationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar campeonato' : 'Novo campeonato'),
        leading: const BackButton(),
      ),
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
                  initialValue:
                      _organizationId.text.isEmpty ? null : _organizationId.text,
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
                      setState(() => _organizationId.text = value ?? ''),
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
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CompetitionStatus>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: CompetitionStatus.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(_statusLabel(s))))
                    .toList(),
                onChanged: (value) => setState(() => _status = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDate,
                      readOnly: true,
                      onTap: () => _pickDate(_startDate),
                      decoration: const InputDecoration(
                        labelText: 'Início',
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _endDate,
                      readOnly: true,
                      onTap: () => _pickDate(_endDate),
                      decoration: const InputDecoration(
                        labelText: 'Fim',
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
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

  String _statusLabel(CompetitionStatus status) => switch (status) {
        CompetitionStatus.draft => 'Rascunho',
        CompetitionStatus.published => 'Publicado',
        CompetitionStatus.finished => 'Encerrado',
      };
}

String _formatDate(DateTime? date) =>
    date == null ? '' : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
