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
  const DivisionFormArgs({this.categoryId, this.conferenceId});

  final String? categoryId;
  final String? conferenceId;
}

/// Formulário de criação/edição de divisão.
///
/// A conferência é opcional: a divisão pode ficar "sem conferência". Na
/// edição, escolher "Sem conferência" remove o vínculo.
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
  ConsumerState<DivisionFormScreen> createState() =>
      _DivisionFormScreenState();
}

class _DivisionFormScreenState extends ConsumerState<DivisionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  String? _categoryId;
  String? _conferenceId;
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.divisionId != null || widget.division != null;

  @override
  void initState() {
    super.initState();
    final division = widget.division;
    _name = TextEditingController(text: division?.name ?? '');
    _categoryId = division?.categoryId ?? widget.args?.categoryId;
    _conferenceId = division?.conferenceId ?? widget.args?.conferenceId;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final categoryId = _categoryId;
    if (categoryId == null) {
      setState(() => _errorMessage = 'Categoria não informada.');
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
          categoryId: categoryId,
          conferenceId: _conferenceId,
          name: _name.text.trim(),
        );
      } else {
        await api.update(
          id,
          conferenceId: _conferenceId,
          name: _name.text.trim(),
        );
      }
      ref.invalidate(divisionsProvider(categoryId));
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
    final categoryId = _categoryId;
    final categoryName = categoryId == null
        ? ''
        : ref.watch(categoryProvider(categoryId)).valueOrNull?.name ?? '';
    final conferences = categoryId == null
        ? null
        : ref.watch(conferencesProvider(categoryId));

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
                TextFormField(
                  initialValue: categoryName,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                conferences?.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => AppErrorState(
                    message: 'Não foi possível carregar as conferências',
                    onRetry: () =>
                        ref.invalidate(conferencesProvider(categoryId!)),
                  ),
                  data: (items) => DropdownButtonFormField<String?>(
                    initialValue: _conferenceId,
                    decoration: const InputDecoration(
                      labelText: 'Conferência',
                      helperText: 'Opcional',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Sem conferência'),
                      ),
                      ...items
                          .map((c) => DropdownMenuItem<String?>(
                                value: c.id,
                                child: Text(c.name),
                              )),
                    ],
                    onChanged: (value) =>
                        setState(() => _conferenceId = value),
                  ),
                ) ??
                    const LinearProgressIndicator(),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    helperText: 'Ex.: Divisão Norte',
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