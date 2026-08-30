/// Formatos de data padronizados do Admin Web (E1 #457).
///
/// Unifica as ~13 cópias locais de `_formatDate`/`_formatTime`/`_formatDateTime`
/// que existiam nas telas com 3 formatos divergentes (ISO nos forms,
/// `dd/MM/yyyy` nos detalhes, `dd/MM HH:mm` no approvals). Cada função preserva
/// o comportamento original (null-handling e conversão `toLocal`).
library;

/// `yyyy-MM-dd` — usado em formulários/date pickers (competition create/edit).
/// `null` → `''`.
String formatIsoDate(DateTime? date) => date == null
    ? ''
    : '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

/// `dd/MM/yyyy` em hora local — detalhes de entidades (atleta, campeonato,
/// organização, rodada, time, campo, jogo).
/// `null` → `'—'`.
String formatBrDate(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

/// `dd/MM/yyyy HH:mm` — horário de jogo (game_detail).
String formatBrDateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year} '
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';

/// `dd/MM/yyyy HH:mm` — timestamps de usuário (approvals), preservando o
/// formato original com ano.
/// `null` → `'agora'`.
String formatBrShortDateTime(DateTime? value) {
  if (value == null) return 'agora';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} $hour:$minute';
}

/// `HH:mm` — hora de jogo em formulários (game_form).
String formatBrTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';