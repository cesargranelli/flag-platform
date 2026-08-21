import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_back_button.dart';

/// Formulário de criação/edição de conferência.
class ConferenceFormScreen extends ConsumerStatefulWidget {
  const ConferenceFormScreen({
    super.key,
    this.conferenceId,
    this.conference,
    this.competitionId,
  });

  final String? conferenceId;
  final Conference? conference;
  final String? competitionId;

  @override
  ConsumerState<ConferenceFormScreen> createState() =>
      _ConferenceFormScreenState();
}

class _ConferenceFormScreenState extends ConsumerState<ConferenceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing =>
      widget.conferenceId != null || widget.conference != null;

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

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(conferenceApiProvider);
      final id = widget.conferenceId ?? widget.conference?.id;
      final competitionId = widget.competitionId ?? ref.watch(selectedCompetitionProvider) ?? '';
      if (id == null) {
        await api.create(competitionId: competitionId, name: _name.text.trim());
      } else {
        await api.update(id, name: _name.text.trim());
      }
      ref.invalidate(competitionsProvider);
      if (mounted) context.pop();
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível salvar a conferência.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar conferência' : 'Nova conferência'),
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
                TextFormField(
                  controller: _name,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    helperText: 'Ex.: Conferência Leste',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Informe o nome'
                          : null,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600),
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