import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../utils/date_formats.dart';
import '../widgets/app_screen.dart';

/// Argumentos de navegação do formulário de jogo.
typedef GameFormArgs = ({String? competitionId, String? roundId, Game? game});

/// Formulário de criação/edição de jogo.
class GameFormScreen extends ConsumerStatefulWidget {
  const GameFormScreen({super.key, this.args});

  final GameFormArgs? args;

  @override
  ConsumerState<GameFormScreen> createState() => _GameFormScreenState();
}

class _GameFormScreenState extends ConsumerState<GameFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _roundId;
  String? _homeTeamId;
  String? _awayTeamId;
  String? _venueId;
  DateTime? _scheduledAt;
  late final TextEditingController _scheduleController;
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.args?.game != null;

  @override
  void initState() {
    super.initState();
    final game = widget.args?.game;
    _roundId = game?.roundId ?? widget.args?.roundId;
    _homeTeamId = game?.homeTeamId;
    _awayTeamId = game?.awayTeamId;
    _venueId = game?.venueId;
    _scheduledAt = game?.scheduledAt ?? DateTime.now();
    _scheduleController = TextEditingController(text: _formatSchedule());
  }

  @override
  void dispose() {
    _scheduleController.dispose();
    super.dispose();
  }

  String _formatSchedule() {
    final scheduledAt = _scheduledAt;
    return scheduledAt == null
        ? ''
        : '${formatBrDate(scheduledAt)} ${formatBrTime(scheduledAt)}';
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    // Issue #256: calendário do design system (spec Figma) no lugar do
    // showDatePicker padrão. TimePicker permanece inalterado logo após.
    final date = await showAppCalendarDialog(
      context,
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
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _scheduleController.text = _formatSchedule();
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
      if (mounted) {
        if (id != null) {
          // Volta para o detalhe recarregado (busca fresca via provider).
          ref.invalidate(gameProvider(id));
          context.go('/games/$id');
        } else {
          context.pop();
        }
      }
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
    // O campeonato vem dos argumentos de navegação; sem eles (ex.: deep link),
    // usa o campeonato selecionado no contexto global.
    final competitionId =
        widget.args?.competitionId ?? ref.watch(selectedCompetitionProvider);
    final rounds = competitionId == null
        ? null
        : ref.watch(roundsProvider(competitionId));
    final teams = competitionId == null
        ? null
        : ref.watch(teamsProvider(competitionId));
    final venues = ref.watch(venuesProvider);

    return AppScreen(
      title: _isEditing ? 'Editar jogo' : 'Novo jogo',
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem(AppStrings.games, route: '/games'),
        BreadcrumbItem('Formulário'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppLayout.form(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                (rounds?.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => const Text('Erro ao carregar rodadas'),
                      data: (items) => KicksterDropdown<String>(
                        label: 'Rodada',
                        value: _roundId,
                        items: items
                            .map(
                              (r) => DropdownMenuItem(
                                value: r.id,
                                child: Text('Rodada ${r.number} - ${r.name}'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _roundId = value),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Selecione a rodada'
                            : null,
                      ),
                    ) ??
                    const LinearProgressIndicator()),
                const SizedBox(height: 12),
                (teams?.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => const Text('Erro ao carregar times'),
                      data: (items) => KicksterDropdown<String>(
                        label: 'Time da casa',
                        value: _homeTeamId,
                        items: items
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _homeTeamId = value),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Selecione o time da casa'
                            : null,
                      ),
                    ) ??
                    const LinearProgressIndicator()),
                const SizedBox(height: 12),
                (teams?.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => const Text('Erro ao carregar times'),
                      data: (items) => KicksterDropdown<String>(
                        label: 'Time visitante',
                        value: _awayTeamId,
                        items: items
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _awayTeamId = value),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Selecione o time visitante';
                          }
                          if (_homeTeamId != null && value == _homeTeamId) {
                            return 'O time visitante deve ser diferente do time da casa';
                          }
                          return null;
                        },
                      ),
                    ) ??
                    const LinearProgressIndicator()),
                const SizedBox(height: 12),
                venues.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => const Text('Erro ao carregar campos'),
                  data: (items) => KicksterDropdown<String?>(
                    label: 'Campo (opcional)',
                    value: _venueId,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Sem campo'),
                      ),
                      ...items.map(
                        (v) => DropdownMenuItem<String?>(
                          value: v.id,
                          child: Text(v.name),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _venueId = value),
                  ),
                ),
                const SizedBox(height: 12),
                KicksterInput(
                  label: 'Horário',
                  controller: _scheduleController,
                  readOnly: true,
                  onTap: _pickSchedule,
                  hintText: 'Selecione data e hora',
                  suffixIcon: const Icon(Icons.schedule),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: AppColors.danger,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                KicksterButton(
                  label: 'Salvar',
                  icon: Icons.check,
                  loading: _submitting,
                  onPressed: _submitting ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }
}
