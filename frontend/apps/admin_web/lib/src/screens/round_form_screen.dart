import 'package:flag_api/flag_api.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Formulário de criação/edição de rodada.
class RoundFormScreen extends ConsumerStatefulWidget {
  const RoundFormScreen({super.key, this.roundId, this.round, this.initialCategoryId});

  final String? roundId;
  final Round? round;
  final String? initialCategoryId;

  @override
  ConsumerState<RoundFormScreen> createState() => _RoundFormScreenState();
}

class _RoundFormScreenState extends ConsumerState<RoundFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _number;
  String? _categoryId;
  RoundType? _type;
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.roundId != null || widget.round != null;

  @override
  void initState() {
    super.initState();
    final round = widget.round;
    _name = TextEditingController(text: round?.name ?? '');
    _number = TextEditingController(text: round?.number.toString() ?? '');
    _categoryId = round?.categoryId ?? widget.initialCategoryId;
    _type = round?.type ?? RoundType.regular;
  }

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(roundApiProvider);
      final id = widget.roundId ?? widget.round?.id;
      if (id == null) {
        await api.create(
          categoryId: _categoryId!,
          number: int.parse(_number.text.trim()),
          name: _name.text.trim(),
          type: _type!,
        );
      } else {
        await api.update(
          id,
          categoryId: _categoryId!,
          number: int.parse(_number.text.trim()),
          name: _name.text.trim(),
          type: _type!,
        );
      }
      if (_categoryId != null) ref.invalidate(roundsProvider(_categoryId!));
      if (mounted) context.pop();
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível salvar a rodada.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);
    final compItems = competitions.valueOrNull ?? const [];
    final effectiveComp = ref.watch(selectedCompetitionProvider) ??
        (compItems.isNotEmpty ? compItems.first.id : null);
    final categories = effectiveComp == null
        ? null
        : ref.watch(categoriesProvider(effectiveComp));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar rodada' : 'Nova rodada'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              (categories?.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => const Text('Erro ao carregar categorias'),
                data: (items) => DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: items
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _categoryId = value),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Selecione a categoria' : null,
                ),
              ) ??
              const LinearProgressIndicator()),
              const SizedBox(height: 12),
              TextFormField(
                controller: _number,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o número';
                  }
                  return int.tryParse(value.trim()) == null
                      ? 'Número inválido'
                      : null;
                },
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
              DropdownButtonFormField<RoundType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: RoundType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (value) => setState(() => _type = value),
                validator: (value) => value == null ? 'Selecione o tipo' : null,
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
}
