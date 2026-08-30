import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../utils/mutation.dart';

/// Modal de criação/edição de conferência (issue #258).
///
/// Padrão do app: `showDialog` + `AlertDialog` com largura coerente com
/// `AppLayout.maxFormWidth` (600px). Substitui as rotas
/// `/conferences/new` e `/conferences/{id}/edit`.
Future<void> showConferenceFormModal(
  BuildContext context, {
  required String competitionId,
  Conference? conference,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ConferenceFormModal(
      competitionId: competitionId,
      conference: conference,
    ),
  );
}

class ConferenceFormModal extends ConsumerStatefulWidget {
  const ConferenceFormModal({
    super.key,
    required this.competitionId,
    this.conference,
  });

  final String competitionId;

  /// Presente em modo edição.
  final Conference? conference;

  @override
  ConsumerState<ConferenceFormModal> createState() =>
      _ConferenceFormModalState();
}

class _ConferenceFormModalState extends ConsumerState<ConferenceFormModal> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;

  static const _scope = 'conference-form';

  bool get _isEditing => widget.conference != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.conference?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await runMutation(
      context,
      ref: ref,
      scope: _scope,
      action: () async {
        final api = ref.read(conferenceApiProvider);
        if (_isEditing) {
          await api.update(widget.conference!.id, name: _name.text.trim());
        } else {
          await api.create(
            competitionId: widget.competitionId,
            name: _name.text.trim(),
          );
        }
      },
      successMessage:
          _isEditing ? 'Conferência atualizada.' : 'Conferência criada.',
      errorMessage: 'Não foi possível salvar a conferência.',
      progressId: 'save',
      onSuccess: () {
        ref.invalidate(conferencesProvider(widget.competitionId));
        if (mounted) Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final submitting =
        ref.watch(mutationProgressProvider(_scope)).contains('save');
    return AlertDialog(
      title: Text(_isEditing ? 'Editar conferência' : 'Nova conferência'),
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
                hintText: 'Ex.: Conferência Leste',
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Informe o nome'
                    : null,
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
