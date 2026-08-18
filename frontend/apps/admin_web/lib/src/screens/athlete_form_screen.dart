import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_back_button.dart';

/// Formulário de criação/edição de atleta.
class AthleteFormScreen extends ConsumerStatefulWidget {
  const AthleteFormScreen({super.key, this.athleteId, this.athlete});

  final String? athleteId;
  final Athlete? athlete;

  @override
  ConsumerState<AthleteFormScreen> createState() => _AthleteFormScreenState();
}

class _AthleteFormScreenState extends ConsumerState<AthleteFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _nickname;
  late final TextEditingController _number;
  late final TextEditingController _photoUrl;
  AthletePosition? _position;
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.athleteId != null || widget.athlete != null;

  @override
  void initState() {
    super.initState();
    final athlete = widget.athlete;
    _name = TextEditingController(text: athlete?.name ?? '');
    _nickname = TextEditingController(text: athlete?.nickname ?? '');
    _number = TextEditingController(text: athlete?.number?.toString() ?? '');
    _photoUrl = TextEditingController(text: athlete?.photoUrl ?? '');
    _position = athlete?.position;
  }

  @override
  void dispose() {
    for (final controller in [_name, _nickname, _number, _photoUrl]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return int.tryParse(value.trim()) == null
        ? 'Informe um número válido'
        : null;
  }

  String? _validatePhotoUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    final valid = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return valid ? null : 'Informe uma URL válida (http/https)';
  }

  Map<String, dynamic> _body() => {
        'name': _name.text.trim(),
        if (_nickname.text.trim().isNotEmpty) 'nickname': _nickname.text.trim(),
        if (_position != null) 'position': _position!.toJson(),
        if (int.tryParse(_number.text.trim()) != null)
          'number': int.parse(_number.text.trim()),
        if (_photoUrl.text.trim().isNotEmpty) 'photoUrl': _photoUrl.text.trim(),
      };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(athleteApiProvider);
      final id = widget.athleteId ?? widget.athlete?.id;
      if (id == null) {
        await api.create(_body());
      } else {
        await api.update(id, _body());
      }
      ref.invalidate(athletesProvider);
      if (mounted) {
        if (id != null) {
          // Volta para o detalhe recarregado (busca fresca via provider).
          ref.invalidate(athleteProvider(id));
          context.go('/athletes/$id');
        } else {
          context.pop();
        }
      }
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível salvar o atleta.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar atleta' : 'Novo atleta'),
        leading: AppBackButton(fallbackRoute: '/athletes'),
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
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Informe o nome'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nickname,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Apelido',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AthletePosition>(
                  initialValue: _position,
                  decoration: const InputDecoration(
                    labelText: 'Posição',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<AthletePosition>(
                        value: null, child: Text('Sem posição')),
                    ...AthletePosition.values.map((p) =>
                        DropdownMenuItem<AthletePosition>(
                          value: p,
                          child: Text(p.label),
                        )),
                  ],
                  onChanged: (value) => setState(() => _position = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _number,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  decoration: const InputDecoration(
                    labelText: 'Número da camisa',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateNumber,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _photoUrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL da foto',
                    helperText: 'Ex.: https://...',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validatePhotoUrl,
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
