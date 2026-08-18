import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_back_button.dart';

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

    final categoryId = _categoryId;
    final type = _type;
    if (categoryId == null || type == null) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final previousCategoryId = widget.round?.categoryId;
    try {
      final api = ref.read(roundApiProvider);
      final id = widget.roundId ?? widget.round?.id;
      if (id == null) {
        await api.create(
          categoryId: categoryId,
          number: int.parse(_number.text.trim()),
          name: _name.text.trim(),
          type: type,
        );
      } else {
        await api.update(
          id,
          categoryId: categoryId,
          number: int.parse(_number.text.trim()),
          name: _name.text.trim(),
          type: type,
        );
      }
      ref.invalidate(roundsProvider(categoryId));
      if (previousCategoryId != null && previousCategoryId != categoryId) {
        ref.invalidate(roundsProvider(previousCategoryId));
      }
      if (mounted) {
        if (id != null) {
          // Volta para o detalhe recarregado (busca fresca via provider).
          ref.invalidate(roundProvider(id));
          context.go('/rounds/$id');
        } else {
          context.pop();
        }
      }
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível salvar a rodada.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o número';
    }
    final number = int.tryParse(value.trim());
    if (number == null) return 'Número inválido';
    if (number < 1) return 'O número deve ser maior ou igual a 1';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Na edição, o campeonato é derivado da categoria da rodada (não do estado
    // global selectedCompetitionProvider, que pode apontar para outro
    // campeonato). Na criação, usa o contexto global como fallback.
    final editingRoundCategoryId = widget.round?.categoryId;
    final editingCategory =
        editingRoundCategoryId != null && widget.round != null
            ? ref.watch(categoryProvider(editingRoundCategoryId)).valueOrNull
            : null;
    final competitions = ref.watch(competitionsProvider);
    final compItems = competitions.valueOrNull ?? const [];
    final effectiveComp = editingCategory?.competitionId ??
        (ref.watch(selectedCompetitionProvider) ??
            (compItems.isNotEmpty ? compItems.first.id : null));
    final categories = effectiveComp == null
        ? null
        : ref.watch(categoriesProvider(effectiveComp));
    final defaultCategoryId = widget.round?.categoryId ??
        (widget.roundId == null
            ? (widget.initialCategoryId ?? ref.read(selectedCategoryProvider))
            : null);
    final categoryValue = _categoryId ?? defaultCategoryId;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar rodada' : 'Nova rodada'),
        leading: AppBackButton(fallbackRoute: '/rounds'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppLayout.form(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                (categories?.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => AppErrorState(
                    message: 'Não foi possível carregar as categorias',
                    onRetry: () =>
                        ref.invalidate(categoriesProvider(effectiveComp!)),
                  ),
                  data: (items) => DropdownButtonFormField<String>(
                    initialValue: categoryValue,
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
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Selecione a categoria'
                        : null,
                  ),
                ) ??
                const LinearProgressIndicator()),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _number,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  maxLength: 3,
                  decoration: const InputDecoration(
                    labelText: 'Número',
                    helperText: 'Ex.: 1',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateNumber,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  maxLength: 100,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Informe o nome'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RoundType>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    helperText: 'Fases: Regular, Playoffs, Wildcard, Semifinal, Final',
                    border: OutlineInputBorder(),
                  ),
                  items: RoundType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (value) => setState(() => _type = value),
                  validator: (value) => value == null ? 'Selecione o tipo' : null,
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
