import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_back_button.dart';

/// Formulário de criação/edição de campeonato.
class CompetitionFormScreen extends ConsumerStatefulWidget {
  const CompetitionFormScreen({
    super.key,
    this.competitionId,
    this.competition,
  });

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
  late final TextEditingController _modalityId;
  late final TextEditingController _gender;
  late final TextEditingController _ageGroup;

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
    _modalityId = TextEditingController(text: competition?.modalityId?.toString() ?? '');
    _gender = TextEditingController(text: competition?.gender ?? '');
    _ageGroup = TextEditingController(text: competition?.ageGroup ?? '');
    _status = competition?.status;
  }

  @override
  void dispose() {
    for (final controller in [
      _name, _description, _organizationId, _startDate, _endDate,
      _modalityId, _gender, _ageGroup,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatDate(DateTime? date) =>
      date == null ? '' : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
      final orgId = _organizationId.text.trim();
      final modalityText = _modalityId.text.trim();
      final modalityId = modalityText.isNotEmpty
          ? Uint8List.fromList(modalityText.split('.').map(int.parse).toList())
          : null;
      final gender = _gender.text.isNotEmpty ? _gender.text : null;
      final ageGroup = _ageGroup.text.isNotEmpty ? _ageGroup.text : null;

      final id = widget.competitionId ?? widget.competition?.id;
      if (id == null) {
        await api.create(
          organizationId: orgId,
          name: _name.text.trim(),
          description: _description.text.trim(),
          startDate: _startDate.text.isEmpty ? null : _startDate.text,
          endDate: _endDate.text.isEmpty ? null : _endDate.text,
          status: _status,
          modalityId: modalityId,
          gender: gender,
          ageGroup: ageGroup,
        );
      } else {
        await api.update(
          id,
          organizationId: orgId,
          name: _name.text.trim(),
          description: _description.text.trim(),
          startDate: _startDate.text.isEmpty ? null : _startDate.text,
          endDate: _endDate.text.isEmpty ? null : _endDate.text,
          status: _status,
          modalityId: modalityId,
          gender: gender,
          ageGroup: ageGroup,
        );
      }
      ref.invalidate(competitionsProvider);
      if (mounted) {
        context.go('/competitions/$id');
      }
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
    final modalities = ref.watch(modalitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar campeonato' : 'Novo campeonato'),
        leading: AppBackButton(fallbackRoute: '/competitions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppLayout.form(
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
                      child: DropdownButtonFormField<String>(
                        value: _modalityId.text.isNotEmpty ? _modalityId.text : null,
                        decoration: const InputDecoration(
                          labelText: 'Modalidade',
                          border: OutlineInputBorder(),
                        ),
                        items: modalities
                            .map((m) => DropdownMenuItem(
                                  value: m.id.toString(),
                                  child: Text(m.name),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _modalityId.text = value ?? ''),
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Selecione a modalidade' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _gender.isNotEmpty ? _gender.text : null,
                        decoration: const InputDecoration(
                          labelText: 'Gênero',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'MALE', child: Text('Masculino')),
                          DropdownMenuItem(value: 'FEMALE', child: Text('Feminino')),
                          DropdownMenuItem(value: 'MIXED', child: Text('Misto')),
                        ],
                        onChanged: (value) =>
                            setState(() => _gender = value != null ? value : ''),
                        validator: (value) => (value == null || value.isEmpty) ? 'Selecione o gênero' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _ageGroup.isNotEmpty ? _ageGroup.text : null,
                    decoration: const InputDecoration(
                      labelText: 'Faixa etária',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'SUB11', child: Text('Sub-11')),
                      DropdownMenuItem(value: 'SUB13', child: Text('Sub-13')),
                      DropdownMenuItem(value: 'SUB14', child: Text('Sub-14')),
                      DropdownMenuItem(value: 'SUB15', child: Text('Sub-15')),
                      DropdownMenuItem(value: 'SUB17', child: Text('Sub-17')),
                      DropdownMenuItem(value: 'SUB20', child: Text('Sub-20')),
                      DropdownMenuItem(value: 'ADULT', child: Text('Adulto')),
                      DropdownMenuItem(value: 'MASTER', child: Text('Master')),
                      DropdownMenuItem(value: 'OPEN', child: Text('Livre')),
                    ],
                    onChanged: (value) =>
                        setState(() => _ageGroup = value != null ? value : ''),
                    validator: (value) => (value == null || value.isEmpty) ? 'Selecione a faixa etária' : null,
                  ),
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
],
),
);
}

String _statusLabel(CompetitionStatus status) => switch (status) {
  CompetitionStatus.draft => 'Rascunho',
  CompetitionStatus.published => 'Publicado',
  CompetitionStatus.finished => 'Encerrado',
};