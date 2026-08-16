import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
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

    final competitionId = _competitionId;
    if (competitionId == null) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final previousCompetitionId = widget.category?.competitionId;
    try {
      final api = ref.read(categoryApiProvider);
      final id = widget.categoryId ?? widget.category?.id;
      if (id == null) {
        await api.create(competitionId: competitionId, name: _name.text.trim());
      } else {
        await api.update(id, competitionId: competitionId, name: _name.text.trim());
      }
      ref.invalidate(categoriesProvider(competitionId));
      if (previousCompetitionId != null && previousCompetitionId != competitionId) {
        ref.invalidate(categoriesProvider(previousCompetitionId));
      }
      if (mounted) {
        if (id != null) {
          // Volta para o detalhe recarregado (busca fresca via provider).
          context.go('/categories/$id');
        } else {
          context.pop();
        }
      }
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível salvar a categoria.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o nome';
    }
    final competitionId = _competitionId;
    if (competitionId == null) return null;
    final items = ref.read(categoriesProvider(competitionId)).valueOrNull;
    if (items != null) {
      final editingId = widget.categoryId ?? widget.category?.id;
      final exists = items.any(
        (c) =>
            c.id != editingId &&
            c.name.trim().toLowerCase() == value.trim().toLowerCase(),
      );
      if (exists) {
        return 'Já existe uma categoria com este nome neste campeonato';
      }
    }
    return null;
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppLayout.form(
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
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateName,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
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
      ),
    );
  }
}
