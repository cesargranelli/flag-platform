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
    this.roundId,
    this.competitionId,
  });

  /// Rodada de contexto; `null` quando a rota é aberta sem extra (deep-link)
  /// — nesse caso a tela mostra um estado vazio em vez de chamar a API (B5).
  final String? roundId;
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
          KicksterButton(
            label: 'Fechar',
            variant: KicksterButtonVariant.text,
            onPressed: () => Navigator.pop(context),
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
    final roundId = widget.roundId;
    if (roundId == null || roundId.isEmpty) return;
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
          .createBatch(roundId, items);
      ref.invalidate(gamesByRoundProvider(roundId));
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
    final roundId = widget.roundId;

    // Deep-link direto para /games/import sem rodada: estado vazio em vez de
    // chamar a API com ID vazio (B5 #457).
    if (roundId == null || roundId.isEmpty) {
      return AppScreen(
        title: 'Importar jogos',
        breadcrumb: const [
          BreadcrumbItem('Início', route: '/'),
          BreadcrumbItem(AppStrings.games, route: '/games'),
          BreadcrumbItem('Importar'),
        ],
        body: AppLayout.form(
          child: KicksterEmptyState(
            icon: Icons.sports,
            message: 'Rodada não identificada',
            description:
                'Selecione uma rodada no módulo Jogos para importar partidas.',
            action: KicksterButton(
              label: 'Ir para Jogos',
              icon: Icons.arrow_back,
              onPressed: () => context.go('/games'),
            ),
          ),
        ),
      );
    }

    return AppScreen(
      title: 'Importar jogos',
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem(AppStrings.games, route: '/games'),
        BreadcrumbItem('Importar'),
      ],
      body: AppLayout.form(
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
              KicksterButton(
                label: 'Ver modelo CSV',
                onPressed: _showTemplate,
                variant: KicksterButtonVariant.outline,
                icon: Icons.download_outlined,
              ),
              const SizedBox(height: 12),
              KicksterButton(
                label: 'Selecionar arquivo',
                onPressed: _pickFile,
                icon: Icons.upload_file,
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
                KicksterButton(
                  label: 'Importar',
                  onPressed: _importing ? null : _import,
                  loading: _importing,
                ),
              ],
            ] else ...[
              _resultSummary(result),
              const SizedBox(height: 16),
              _resultTable(result),
              const SizedBox(height: 24),
              KicksterButton(
                label: 'Concluir',
                onPressed: () => context.go('/games'),
                icon: Icons.check,
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
    );
  }

  Widget _resultSummary(GameBatchResult result) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        KicksterBadge(
          label: '${result.imported} importados',
          color: AppColors.success,
        ),
        KicksterBadge(
          label: '${result.skipped} ignorados',
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _resultTable(GameBatchResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resultado por linha',
          style: TextStyle(fontWeight: FontWeight.w700),
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
