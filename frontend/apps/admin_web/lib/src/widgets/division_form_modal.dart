import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../utils/mutation.dart';

/// Valor-sentinela da opção "— sem conferência —" do dropdown.
const String _kNoConference = '';

/// Modal de criação/edição de divisão (issue #258).
///
/// Padrão do app: `showDialog` + `AlertDialog` com largura coerente com
/// `AppLayout.maxFormWidth` (600px). Substitui as rotas
/// `/divisions/new` e `/divisions/{id}/edit`.
Future<void> showDivisionFormModal(
  BuildContext context, {
  required String competitionId,
  Division? division,
  String? initialConferenceId,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => DivisionFormModal(
      competitionId: competitionId,
      division: division,
      initialConferenceId: initialConferenceId,
    ),
  );
}

class DivisionFormModal extends ConsumerStatefulWidget {
  const DivisionFormModal({
    super.key,
    required this.competitionId,
    this.division,
    this.initialConferenceId,
  });

  final String competitionId;

  /// Presente em modo edição.
  final Division? division;

  /// Conferência pré-selecionada ao criar a partir de um card de conferência.
  final String? initialConferenceId;

  @override
  ConsumerState<DivisionFormModal> createState() => _DivisionFormModalState();
}

class _DivisionFormModalState extends ConsumerState<DivisionFormModal> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late String? _conferenceId;

  static const _scope = 'division-form';

  bool get _isEditing => widget.division != null;

  @override
  void initState() {
    super.initState();
    final division = widget.division;
    _name = TextEditingController(text: division?.name ?? '');
    // Correção do bug da issue #258: em edição, preserva a conferência atual
    // da divisão (antes o form sempre salvava com conferenceId null).
    // Em criação, usa a conferência de contexto, quando houver.
    _conferenceId =
        division?.conferenceId ?? widget.initialConferenceId ?? _kNoConference;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final conferenceId =
        (_conferenceId == _kNoConference || _conferenceId == null)
            ? null
            : _conferenceId;

    await runMutation(
      context,
      ref: ref,
      scope: _scope,
      action: () async {
        final api = ref.read(divisionApiProvider);
        if (_isEditing) {
          await api.update(
            widget.division!.id,
            competitionId: widget.competitionId,
            conferenceId: conferenceId,
            name: _name.text.trim(),
          );
        } else {
          await api.create(
            competitionId: widget.competitionId,
            conferenceId: conferenceId,
            name: _name.text.trim(),
          );
        }
      },
      successMessage: _isEditing ? 'Divisão atualizada.' : 'Divisão criada.',
      errorMessage: 'Não foi possível salvar a divisão.',
      progressId: 'save',
      onSuccess: () {
        ref.invalidate(divisionsProvider(widget.competitionId));
        if (mounted) Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final conferences = ref.watch(conferencesProvider(widget.competitionId));
    final confItems = conferences.valueOrNull ?? const <Conference>[];
    final submitting =
        ref.watch(mutationProgressProvider(_scope)).contains('save');

    return AlertDialog(
      title: Text(_isEditing ? 'Editar divisão' : 'Nova divisão'),
      content: SizedBox(
        width: AppLayout.maxFormWidth,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KicksterInput(
                label: 'Nome',
                controller: _name,
                maxLength: 100,
                hintText: 'Ex.: Divisão Geral',
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Informe o nome'
                    : null,
              ),
              const SizedBox(height: 12),
              conferences.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, s) =>
                    const Text('Erro ao carregar conferências'),
                data: (_) {
                  final items = <DropdownMenuItem<String>>[
                    const DropdownMenuItem(
                      value: _kNoConference,
                      child: Text('— sem conferência —'),
                    ),
                    ...confItems.map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ),
                  ];
                  // A conferência atual pode ter sido removida em outra
                  // sessão; mantém como opção para não quebrar o dropdown.
                  final currentId = _conferenceId;
                  if (currentId != null &&
                      currentId != _kNoConference &&
                      !confItems.any((c) => c.id == currentId)) {
                    items.insert(
                      1,
                      DropdownMenuItem(
                        value: currentId,
                        child: const Text('Conferência atual (indisponível)'),
                      ),
                    );
                  }
                  return KicksterDropdown<String>(
                    label: 'Conferência',
                    value: currentId ?? _kNoConference,
                    items: items,
                    onChanged: (value) =>
                        setState(() => _conferenceId = value),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        KicksterButton(
          label: 'Cancelar',
          variant: KicksterButtonVariant.text,
          onPressed: submitting ? null : () => Navigator.pop(context),
        ),
        KicksterButton(
          label: 'Salvar',
          onPressed: submitting ? null : _save,
          icon: Icons.check,
          loading: submitting,
        ),
      ],
    );
  }
}
