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

/// Importação em lote de atletas para o elenco de um time (CSV/TXT).
///
/// O time vem do contexto da tela (teamId). O CSV referencia atletas por nome;
/// a resolução nome -> id acontece aqui, tratando homônimos sem resolução
/// silenciosa.
class RosterImportScreen extends ConsumerStatefulWidget {
  const RosterImportScreen({super.key, this.teamId});

  final String? teamId;

  @override
  ConsumerState<RosterImportScreen> createState() => _RosterImportScreenState();
}

class _RosterImportScreenState extends ConsumerState<RosterImportScreen> {
  static const _maxLines = 500;

  List<String>? _atletaNames;
  Map<String, String>? _resolved; // nome -> athleteId
  RosterBatchResult? _result;
  bool _importing = false;
  String? _errorMessage;

  void _showTemplate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modelo CSV'),
        content: const Text(
          'Use o formato abaixo (ponto-e-vírgula, UTF-8):\n\n'
          'atleta;status\n'
          'Maria Silva;ativo\n'
          'João Souza;\n\n'
          'Coluna "atleta" (obrigatória) é o nome cadastrado. '
          'Coluna "status" (opcional) é ativo ou inativo.',
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
      _atletaNames = null;
      _resolved = null;
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
      final names = _parseCsv(content);
      if (names.isEmpty) {
        setState(() => _errorMessage = 'Nenhuma linha válida encontrada.');
        return;
      }
      if (names.length > _maxLines) {
        setState(
          () => _errorMessage = 'Máximo de $_maxLines linhas por arquivo.',
        );
        return;
      }
      setState(() => _atletaNames = names);
      _resolveAthletes(names);
    } catch (_) {
      setState(() => _errorMessage = 'Arquivo inválido. Verifique o formato.');
    }
  }

  List<String> _parseCsv(String content) {
    final lines = content
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];
    final delimiter = _detectDelimiter(lines.first);
    final headers = _splitLine(lines.first, delimiter);
    final nameIndex = headers.indexOf('atleta');

    final names = <String>[];
    for (var i = 1; i < lines.length; i++) {
      final values = _splitLine(lines[i], delimiter);
      if (nameIndex >= 0 && nameIndex < values.length) {
        final name = values[nameIndex].trim();
        if (name.isNotEmpty) names.add(name);
      }
    }
    return names;
  }

  String _detectDelimiter(String line) {
    if (line.contains(';')) return ';';
    if (line.contains(',')) return ',';
    return '\t';
  }

  List<String> _splitLine(String line, String delimiter) =>
      line.split(delimiter).map((s) => s.trim()).toList();

  Future<void> _resolveAthletes(List<String> names) async {
    setState(() => _errorMessage = null);
    final athletes = await ref.read(athletesProvider.future);
    if (!mounted) return;

    final resolved = <String, String>{};
    for (final name in names) {
      final matches = athletes
          .where((a) => a.name.trim().toLowerCase() == name.toLowerCase())
          .toList();
      if (matches.length == 1) {
        resolved[name] = matches.first.id;
      }
      // Homônimos: deixa sem resolução -> linha bloqueada na pré-visualização.
    }
    if (mounted) setState(() => _resolved = resolved);
  }

  Future<void> _import() async {
    final teamId = widget.teamId;
    if (teamId == null || teamId.isEmpty) return;

    final resolved = _resolved;
    final names = _atletaNames;
    if (resolved == null || names == null) return;

    final items = <Map<String, dynamic>>[];
    for (final name in names) {
      final id = resolved[name];
      if (id != null) items.add({'athleteId': id});
    }
    setState(() {
      _importing = true;
      _errorMessage = null;
    });
    try {
      final result = await ref
          .read(rosterApiProvider)
          .createBatch(teamId, items);
      ref.invalidate(rosterProvider(teamId));
      if (mounted) setState(() => _result = result);
    } on RepositoryException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Não foi possível importar o elenco.');
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamId = widget.teamId;
    final names = _atletaNames;
    final resolved = _resolved;
    final result = _result;

    // Deep-link direto para /rosters/import sem contexto de time: mostra
    // estado vazio em vez de chamar a API com ID vazio (#457).
    if (teamId == null || teamId.isEmpty) {
      return AppScreen(
        title: 'Importar elenco',
        breadcrumb: const [
          BreadcrumbItem('Início', route: '/'),
          BreadcrumbItem(AppStrings.rosters, route: '/rosters'),
          BreadcrumbItem('Importar'),
        ],
        body: AppLayout.form(
          child: KicksterEmptyState(
            icon: Icons.groups_outlined,
            message: 'Time não identificado',
            description:
                'Selecione um time no módulo Elencos para importar atletas.',
            action: KicksterButton(
              label: 'Ir para Elencos',
              icon: Icons.arrow_back,
              onPressed: () => context.go('/rosters'),
            ),
          ),
        ),
      );
    }

    return AppScreen(
      title: 'Importar elenco',
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem(AppStrings.rosters, route: '/rosters'),
        BreadcrumbItem('Importar'),
      ],
      body: AppLayout.form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (result == null) ...[
              Text(
                'Importe vários atletas para o elenco do time a partir de um arquivo CSV/TXT.',
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
              if (names != null && resolved != null) ...[
                Text(
                  '${names.length} ${names.length == 1 ? 'atleta' : 'atletas'} lidos.',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                _preview(resolved, names),
                const SizedBox(height: 16),
                KicksterButton(
                  label:
                      'Importar ${resolved.values.length} '
                      '${resolved.values.length == 1 ? 'atleta' : 'atletas'}',
                  onPressed: (resolved.values.isEmpty || _importing)
                      ? null
                      : _import,
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
                onPressed: () => context.go('/rosters'),
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

  Widget _preview(Map<String, String> resolved, List<String> names) {
    final valid = names.where((n) => resolved.containsKey(n)).toList();
    final blocked = names.where((n) => !resolved.containsKey(n)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            KicksterBadge(
              label: '${valid.length} resolvidos',
              color: AppColors.success,
            ),
            KicksterBadge(
              label: '${blocked.length} ambíguos/não encontrados',
              color: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Pré-visualização',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        for (final name in names.take(15))
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              resolved.containsKey(name)
                  ? '✓ $name'
                  : '! $name (atleta não encontrado ou ambíguo)',
              style: const TextStyle(fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _resultSummary(RosterBatchResult result) {
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

  Widget _resultTable(RosterBatchResult result) {
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
