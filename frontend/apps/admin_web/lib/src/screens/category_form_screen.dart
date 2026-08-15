import 'package:flag_api/flag_api.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Formulário de criação/edição de categoria.
class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.categoryId, this.category});

  final String? categoryId;
  final Category? category;

  @override
  ConsumerState<CategoryFormScreen> createState() =>
      _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  String? _competitionId;
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.categoryId != null || widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _name = TextEditingController(text: category?.name ?? '');
    _competitionId = category?.competitionId ??
        (widget.categoryId == null ? ref.read(selectedCompetitionProvider) : null);
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
      final api = ref.read(categoryApiProvider);
      final id = widget.categoryId ?? widget.category?.id;
      if (id == null) {
        await api.create(
          competitionId: _competitionId!,
          name: _name.text.trim(),
        );
      } else {
        await api.update(
          id,
          competitionId: _competitionId!,
          name: _name.text.trim(),
        );
      }
      if (_competitionId != null) {
        ref.invalidate(categoriesProvider(_competitionId!));
      }
      if (mounted) context.pop();
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível salvar a categoria.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir categoria'),
        content: const Text('Tem certeza que deseja excluir esta categoria?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final id = widget.categoryId ?? widget.category!.id;
    await ref.read(categoryApiProvider).delete(id);
    if (_competitionId != null) {
      ref.invalidate(categoriesProvider(_competitionId!));
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);
    final defaultCompetitionId = widget.category?.competitionId ??
        (widget.categoryId == null
            ? ref.read(selectedCompetitionProvider)
            : null);
    final competitionValue = _competitionId ?? defaultCompetitionId;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar categoria' : 'Nova categoria'),
        leading: const BackButton(),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              competitions.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => const Text('Erro ao carregar campeonatos'),
                data: (items) => DropdownButtonFormField<String>(
                  initialValue: competitionValue,
                  decoration: const InputDecoration(
                    labelText: 'Campeonato',
                    border: OutlineInputBorder(),
                  ),
                  items: items
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _competitionId = value),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Selecione o campeonato' : null,
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
