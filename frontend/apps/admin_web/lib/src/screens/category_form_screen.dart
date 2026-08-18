import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_back_button.dart';

/// Formulário de criação/edição de categoria.
///
/// A categoria é a combinação modalidade + gênero + faixa etária; o nome é
/// derivado automaticamente (override opcional).
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
  String? _modalityId;
  Gender? _gender;
  AgeGroup? _ageGroup;
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
    _modalityId = category?.modalityId;
    _gender = category?.gender;
    _ageGroup = category?.ageGroup;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? _deriveName() {
    if (_gender == null || _ageGroup == null) return null;
    final modality = ref
        .read(modalitiesProvider)
        .valueOrNull
        ?.where((m) => m.id == _modalityId)
        .firstOrNull;
    if (modality == null) return null;
    return '${modality.label} · ${_gender!.label} · ${_ageGroup!.label}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final competitionId = _competitionId;
    final modalityId = _modalityId;
    final gender = _gender;
    final ageGroup = _ageGroup;
    if (competitionId == null || modalityId == null || gender == null || ageGroup == null) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final previousCompetitionId = widget.category?.competitionId;
    final name = _name.text.trim().isEmpty ? null : _name.text.trim();
    try {
      final api = ref.read(categoryApiProvider);
      final id = widget.categoryId ?? widget.category?.id;
      if (id == null) {
        await api.create(
          competitionId: competitionId,
          modalityId: modalityId,
          gender: gender,
          ageGroup: ageGroup,
          name: name,
        );
      } else {
        await api.update(
          id,
          competitionId: competitionId,
          modalityId: modalityId,
          gender: gender,
          ageGroup: ageGroup,
          name: name,
        );
      }
      ref.invalidate(categoriesProvider(competitionId));
      if (previousCompetitionId != null && previousCompetitionId != competitionId) {
        ref.invalidate(categoriesProvider(previousCompetitionId));
      }
      if (mounted) {
        if (id != null) {
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

  String? _validateCombination() {
    if (_modalityId == null || _gender == null || _ageGroup == null) return null;
    final competitionId = _competitionId;
    if (competitionId == null) return null;
    final items = ref.read(categoriesProvider(competitionId)).valueOrNull;
    if (items != null) {
      final editingId = widget.categoryId ?? widget.category?.id;
      final exists = items.any(
        (c) =>
            c.id != editingId &&
            c.modalityId == _modalityId &&
            c.gender == _gender &&
            c.ageGroup == _ageGroup,
      );
      if (exists) {
        return 'Já existe esta combinação neste campeonato';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);
    final modalities = ref.watch(modalitiesProvider);
    final defaultCompetitionId = widget.category?.competitionId ??
        (widget.categoryId == null
            ? ref.read(selectedCompetitionProvider)
            : null);
    final competitionValue = _competitionId ?? defaultCompetitionId;
    final derivedName = _deriveName();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar categoria' : 'Nova categoria'),
        leading: AppBackButton(fallbackRoute: '/categories'),
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
                modalities.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) =>
                      const Text('Erro ao carregar modalidades'),
                  data: (items) => DropdownButtonFormField<String>(
                    initialValue: _modalityId,
                    decoration: const InputDecoration(
                      labelText: 'Modalidade',
                      border: OutlineInputBorder(),
                    ),
                    items: items
                        .map((m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(m.label),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() {
                      _modalityId = value;
                      _name.clear();
                    }),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Selecione a modalidade'
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Gender>(
                  initialValue: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Gênero',
                    border: OutlineInputBorder(),
                  ),
                  items: Gender.values
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g.label),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _gender = value;
                    _name.clear();
                  }),
                  validator: (value) => value == null ? 'Selecione o gênero' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AgeGroup>(
                  initialValue: _ageGroup,
                  decoration: const InputDecoration(
                    labelText: 'Faixa etária',
                    border: OutlineInputBorder(),
                  ),
                  items: AgeGroup.values
                      .map((a) => DropdownMenuItem(
                            value: a,
                            child: Text(a.label),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _ageGroup = value;
                    _name.clear();
                  }),
                  validator: (value) =>
                      value == null ? 'Selecione a faixa etária' : null,
                ),
                const SizedBox(height: 12),
                if (derivedName != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nome: $derivedName',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _name,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Nome (opcional)',
                    helperText: 'Deixe em branco para usar o nome automático',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_validateCombination() != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _validateCombination()!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
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
