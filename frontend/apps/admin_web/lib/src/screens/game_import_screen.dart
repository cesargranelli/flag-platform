import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

typedef GameImportArgs = ({String roundId, String? competitionId});

/// Importação em lote de jogos para uma rodada (CSV/TXT).
///
/// A rodada vem do contexto da tela (roundId). O CSV referencia times/campo
/// por nome; a resolução nome -> id acontece aqui, tratando homônimos sem
/// resolução silenciosa.
class GameImportScreen extends ConsumerStatefulWidget {
  const GameImportScreen({
    super.key,
    required this.roundId,
    this.competitionId,
  });

  final String roundId;
  final String? competitionId;

  @override
  ConsumerState<GameImportScreen> createState() => _GameImportScreenState();
}

class _GameImportScreenState extends ConsumerState<GameImportScreen> {
  static const _maxLines = 500;

  List<_GameRow>? _rows;
  GameBatchResult? _result;
  bool _importing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  void _showTemplate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modelo CSV'),
        content: const Text(
          'Use o formato abaixo (ponto-e-vírgula, UTF-8):\n\n'
          'time_casa;time_fora;campo;data;hora\n'
          'Flamengo FC;Vasco SC;Estádio Laranja;12/05/2026;19:00\n'
          'Fluminense FC;Botafogo SC;;13/05/2026;16:00\n\n'
          'Colunas: time_casa (obrigatório), time_fora (obrigatório), '
          'campo (opcional), data (dd/mm/aaaa), hora (hh:mm).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _rows = null;
      _result = null;
      _errorMessage = null;
    });
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _errorMessage = 'Não foi possível ler o arquivo.');
      return;
    }
    final content = utf8.decode(bytes, allowMalformed: true);
    try {
      final rows = _parseCsv(content);
      if (rows.isEmpty) {
        setState(() => _errorMessage = 'Nenhuma linha válida encontrada.');
        return;
      }
      if (rows.length > _maxLines) {
        setState(
          () => _errorMessage = 'Máximo de $_maxLines linhas por arquivo.',
        );
        return;
      }
      setState(() => _rows = rows);
    } catch (_) {
      setState(() => _errorMessage = 'Arquivo inválido. Verifique o formato.');
    }
  }

  List<_GameRow> _parseCsv(String content) {
    final lines = content
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];
    final delimiter = _detectDelimiter(lines.first);
    final headers = _splitLine(lines.first, delimiter);
    final homeIdx = headers.indexOf('time_casa');
    final awayIdx = headers.indexOf('time_fora');
    final venueIdx = headers.indexOf('campo');
    final dateIdx = headers.indexOf('data');
    final timeIdx = headers.indexOf('hora');

    final rows = <_GameRow>[];
    for (var i = 1; i < lines.length; i++) {
      final values = _splitLine(lines[i], delimiter);
      if (homeIdx >= 0 &&
          homeIdx < values.length &&
          values[homeIdx].isNotEmpty) {
        final home = values[homeIdx].trim();
        final away = awayIdx >= 0 && awayIdx < values.length
            ? values[awayIdx].trim()
            : '';
        final venue = venueIdx >= 0 && venueIdx < values.length
            ? values[venueIdx].trim()
            : '';
        final date = dateIdx >= 0 && dateIdx < values.length
            ? values[dateIdx].trim()
            : '';
        final time = timeIdx >= 0 && timeIdx < values.length
            ? values[timeIdx].trim()
            : '';
        rows.add(_GameRow(home, away, venue, date, time));
      }
    }
    return rows;
  }

  String _detectDelimiter(String line) {
    if (line.contains(';')) return ';';
    if (line.contains(',')) return ',';
    return '\t';
  }

  List<String> _splitLine(String line, String delimiter) =>
      line.split(delimiter).map((s) => s.trim()).toList();

  DateTime? _parseDateTime(String date, String time) {
    final d = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(date);
    final t = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(time);
    if (d == null || t == null) return null;
    final day = int.parse(d.group(1)!);
    final month = int.parse(d.group(2)!);
    final year = int.parse(d.group(3)!);
    final hour = int.parse(t.group(1)!);
    final minute = int.parse(t.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return DateTime(year, month, day, hour, minute);
  }

  Future<void> _import() async {
    final rows = _rows;
    if (rows == null) return;

    final competitionId =
        widget.competitionId ?? ref.read(selectedCompetitionProvider);
    final teams = competitionId == null
        ? const <Team>[]
        : ref.read(teamsProvider(competitionId)).valueOrNull ?? const [];
    final venues = ref.read(venuesProvider).valueOrNull ?? const <Venue>[];

    final items = <Map<String, dynamic>>[];
    for (final row in rows) {
      final homeTeam = teams
          .where((t) => t.name.trim().toLowerCase() == row.home.toLowerCase())
          .toList();
      final awayTeam = teams
          .where((t) => t.name.trim().toLowerCase() == row.away.toLowerCase())
          .toList();
      if (homeTeam.length != 1 || awayTeam.length != 1) {
        continue; // ambíguo/não encontrado
      }
      final scheduledAt = _parseDateTime(row.date, row.time);
      if (scheduledAt == null) continue;
      final venue = row.venue.isEmpty
          ? null
          : venues
                .where(
                  (v) => v.name.trim().toLowerCase() == row.venue.toLowerCase(),
                )
                .toList();
      if (row.venue.isNotEmpty && venue!.length != 1) continue;
      items.add({
        'homeTeamId': homeTeam.first.id,
        'awayTeamId': awayTeam.first.id,
        'venueId': ?(row.venue.isNotEmpty ? venue!.first.id : null),
        'scheduledAt': scheduledAt.toIso8601String(),
      });
    }

    setState(() {
      _importing = true;
      _errorMessage = null;
    });
    try {
      final result = await ref
          .read(gameApiProvider)
          .createBatch(widget.roundId, items);
      ref.invalidate(gamesByRoundProvider(widget.roundId));
      if (mounted) setState(() => _result = result);
    } on RepositoryException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Não foi possível importar os jogos.');
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    final result = _result;

    return AppScreen(
      title: 'Importar jogos',
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem(AppStrings.games, route: '/games'),
        BreadcrumbItem('Importar'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título + actions
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Importar jogos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AppLayout.form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (result == null) ...[
                Text(
                  'Importe vários jogos para a rodada a partir de um arquivo CSV/TXT.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _showTemplate,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Ver modelo CSV'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Selecionar arquivo'),
                ),
                const SizedBox(height: 16),
                if (rows != null) ...[
                  Text(
                    '${rows.length} ${rows.length == 1 ? 'jogo' : 'jogos'} lidos.',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  for (final row in rows.take(15))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${row.home} x ${row.away}'
                        '${row.venue.isNotEmpty ? ' · ${row.venue}' : ''}'
                        ' · ${row.date} ${row.time}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _importing ? null : _import,
                    child: _importing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Importar'),
                  ),
                ],
              ] else ...[
                _resultSummary(result),
                const SizedBox(height: 16),
                _resultTable(result),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/games'),
                  icon: const Icon(Icons.check),
                  label: const Text('Concluir'),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
            ],
          ),
        ),
      ),
      ],
      ),
    );
  }

  Widget _resultSummary(GameBatchResult result) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip('${result.imported} importados', AppColors.success),
        _chip('${result.skipped} ignorados', AppColors.warning),
      ],
    );
  }

  Widget _chip(String text, Color color) {
    // Amarelo `warning` (#FACC15) é claro demais para texto na própria cor
    // sobre o fundo @12%: usa texto escuro (issue #431 — contraste).
    final textColor =
        color == AppColors.warning ? AppColors.textPrimary : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(fontSize: 13, color: textColor)),
    );
  }

  Widget _resultTable(GameBatchResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resultado por linha',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        for (final line in result.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Linha ${line.line}: ${_statusLabel(line.status)}'
              '${line.reason != null ? ' — ${line.reason}' : ''}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
      ],
    );
  }

  String _statusLabel(String status) => switch (status) {
    'IMPORTED' => 'Importado',
    'SKIPPED' => 'Ignorado',
    'INVALID' => 'Inválido',
    _ => status,
  };
}

class _GameRow {
  final String home;
  final String away;
  final String venue;
  final String date;
  final String time;

  const _GameRow(this.home, this.away, this.venue, this.date, this.time);
}
