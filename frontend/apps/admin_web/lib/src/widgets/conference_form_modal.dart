import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

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
  bool _submitting = false;
  String? _errorMessage;

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

    // Capturados antes do await: o contexto do diálogo é desativado no pop.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(conferenceApiProvider);
      if (_isEditing) {
        await api.update(widget.conference!.id, name: _name.text.trim());
      } else {
        await api.create(
          competitionId: widget.competitionId,
          name: _name.text.trim(),
        );
      }
      ref.invalidate(conferencesProvider(widget.competitionId));
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Conferência atualizada.' : 'Conferência criada.',
          ),
        ),
      );
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(
        () => _errorMessage = 'Não foi possível salvar a conferência.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              TextFormField(
                controller: _name,
                maxLength: 100,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  helperText: 'Ex.: Conferência Leste',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Informe o nome'
                    : null,
              ),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        KicksterButton(
          label: 'Cancelar',
          variant: KicksterButtonVariant.text,
          onPressed: _submitting ? null : () => Navigator.pop(context),
        ),
        KicksterButton(
          label: 'Salvar',
          onPressed: _submitting ? null : _save,
          icon: Icons.check,
          loading: _submitting,
        ),
      ],
    );
  }
}
