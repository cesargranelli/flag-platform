/// Formata [value] como `dd/MM/yyyy HH:mm` para exibição em pt-BR.
///
/// Helper compartilhado entre as telas do Referee App (issue #425#16).
String formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString().padLeft(4, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}