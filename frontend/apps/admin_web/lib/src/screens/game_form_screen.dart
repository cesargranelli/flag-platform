import 'package:flag_api/flag_api.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Argumentos de navegação do formulário de jogo.
typedef GameFormArgs = ({String? categoryId, String? roundId, Game? game});

/// Formulário de criação/edição de jogo.
class GameFormScreen extends ConsumerStatefulWidget {
  const GameFormScreen({super.key, this.args});

  final GameFormArgs? args;

  @override
  ConsumerState<GameFormScreen> createState() => _GameFormScreenState();
}

class _GameFormScreenState extends ConsumerState<GameFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _categoryId;
  String? _roundId;
  String? _homeTeamId;
  String? _awayTeamId;
  String? _venueId;
  DateTime? _scheduledAt;
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.args?.game != null;

  @override
  void initState() {
    super.initState();
    final game = widget.args?.game;
    _categoryId = widget.args?.categoryId;
    _roundId = game?.roundId ?? widget.args?.roundId;
    _homeTeamId = game?.homeTeamId;
    _awayTeamId = game?.awayTeamId;
    _venueId = game?.venueId;
    _scheduledAt = game?.scheduledAt ?? DateTime.now();
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? now),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(gameApiProvider);
      final id = widget.args?.game?.id;
      if (id == null) {
        await api.create(
          roundId: _roundId!,
          homeTeamId: _homeTeamId!,
          awayTeamId: _awayTeamId!,
          venueId: _venueId,
          scheduledAt: _scheduledAt!,
        );
      } else {
        await api.update(
          id,
          roundId: _roundId!,
          homeTeamId: _homeTeamId!,
          awayTeamId: _awayTeamId!,
          venueId: _venueId,
          scheduledAt: _scheduledAt!,
        );
      }
      if (_roundId != null) ref.invalidate(gamesByRoundProvider(_roundId!));
      if (mounted) context.pop();
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível salvar o jogo.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rounds = _categoryId == null
        ? null
        : ref.watch(roundsProvider(_categoryId!));
    final teams = _categoryId == null
        ? null
        : ref.watch(teamsProvider(_categoryId!));
    final venues = ref.watch(venuesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar jogo' : 'Novo jogo'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              (rounds?.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => const Text('Erro ao carregar rodadas'),
                data: (items) => DropdownButtonFormField<String>(
                  initialValue: _roundId,
                  decoration: const InputDecoration(
                    labelText: 'Rodada',
                    border: OutlineInputBorder(),
                  ),
                  items: items
                      .map((r) => DropdownMenuItem(
                            value: r.id,
                            child: Text('Rodada ${r.number} - ${r.name}'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _roundId = value),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Selecione a rodada' : null,
                ),
              ) ??
              const LinearProgressIndicator()),
              const SizedBox(height: 12),
              (teams?.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => const Text('Erro ao carregar times'),
                data: (items) => DropdownButtonFormField<String>(
                  initialValue: _homeTeamId,
                  decoration: const InputDecoration(
                    labelText: 'Time da casa',
                    border: OutlineInputBorder(),
                  ),
                  items: items
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                      .toList(),
                  onChanged: (value) => setState(() => _homeTeamId = value),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Selecione o time da casa' : null,
                ),
              ) ??
              const LinearProgressIndicator()),
              const SizedBox(height: 12),
              (teams?.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => const Text('Erro ao carregar times'),
                data: (items) => DropdownButtonFormField<String>(
                  initialValue: _awayTeamId,
                  decoration: const InputDecoration(
                    labelText: 'Time visitante',
                    border: OutlineInputBorder(),
                  ),
                  items: items
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                      .toList(),
                  onChanged: (value) => setState(() => _awayTeamId = value),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Selecione o time visitante' : null,
                ),
              ) ??
              const LinearProgressIndicator()),
              const SizedBox(height: 12),
              venues.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => const Text('Erro ao carregar campos'),
                data: (items) => DropdownButtonFormField<String?>(
                  initialValue: _venueId,
                  decoration: const InputDecoration(
                    labelText: 'Campo (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Sem campo')),
                    ...items.map((v) => DropdownMenuItem<String?>(
                          value: v.id,
                          child: Text(v.name),
                        )),
                  ],
                  onChanged: (value) => setState(() => _venueId = value),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                readOnly: true,
                onTap: _pickSchedule,
                decoration: InputDecoration(
                  labelText: 'Horário',
                  suffixIcon: const Icon(Icons.schedule),
                  border: const OutlineInputBorder(),
                  hintText: _scheduledAt == null
                      ? 'Selecione data e hora'
                      : '${_formatDate(_scheduledAt!)} ${_formatTime(_scheduledAt!)}',
                ),
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

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
String _formatTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
