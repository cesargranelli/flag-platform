import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tamanho do alvo de toque mínimo (tokens.md: "Alvos de toque: mín. 48px").
const double _kTouchTarget = 48;

/// Diâmetro do círculo do dia selecionado/hoje (spec Figma).
const double _kDayCircleSize = 38;

/// Largura-alvo do calendário dentro do diálogo (~360–400px, issue #256).
const double _kCalendarWidth = 380;

/// Raio do container (spec Figma: border-radius 32px).
const double _kContainerRadius = 32;

/// Sombra da spec Figma (`0px 2px 4px rgba(156,156,156,0.25)`).
///
/// O design system não define token de cor de sombra; valor extraído
/// diretamente da especificação do Figma (issue #256).
const Color _kShadowColor = Color(0x409C9C9C);

/// Meses em pt-BR. Lista fixa (em vez de `intl`) para não depender de
/// inicialização de dados de locale no runtime do componente compartilhado.
const List<String> _kMonthNames = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

/// Rótulos dos dias da semana em pt-BR, domingo primeiro (D S T Q Q S S),
/// mesmo padrão do `showDatePicker` com locale pt-BR.
const List<String> _kWeekdayLabels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

/// Abre o calendário do design system em um diálogo modal.
///
/// Substituto direto de `showDatePicker` nas telas do admin web (issue #256).
/// Comportamento:
/// - tocar em um dia válido seleciona-o e fecha o diálogo retornando a data
///   (à meia-noite local);
/// - fechar por fora do diálogo/ESC retorna `null` (cancelamento);
/// - `initialDate` é ajustado (clamp) para dentro de [firstDate..lastDate].
Future<DateTime?> showAppCalendarDialog(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  assert(!firstDate.isAfter(lastDate), 'firstDate deve ser <= lastDate');
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: AppCalendar(
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
        ),
      ),
    ),
  );
}

/// Calendário do design system Flag Platform (issue #256 — spec Figma).
///
/// Especificação implementada:
/// - Container branco (`AppColors.surface`) com raio 32 e sombra sutil;
/// - Header "Mês de Ano" em pt-BR (ex.: "Agosto de 2026"), bold 32px com
///   letter-spacing negativo, `AppColors.textPrimary`, reduzindo
///   automaticamente (FittedBox) quando o nome do mês é longo;
/// - Botões ‹ › circulares, fundo branco, sombra da spec, alvo de toque 48px
///   e tooltips "Mês anterior"/"Próximo mês";
/// - Rótulos D S T Q Q S S (domingo primeiro) bold 12px em
///   `AppColors.accent`;
/// - Dias medium 14px em `AppColors.textPrimary`; dias de outros meses ou
///   fora do intervalo permitido com opacity 0.3 e não interativos;
/// - Dia selecionado: círculo preenchido `AppColors.primary` com texto
///   branco; hoje (não selecionado): contorno sutil.
class AppCalendar extends StatefulWidget {
  const AppCalendar({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  /// Data pré-selecionada (hora é descartada).
  final DateTime initialDate;

  /// Primeira data selecionável.
  final DateTime firstDate;

  /// Última data selecionável.
  final DateTime lastDate;

  @override
  State<AppCalendar> createState() => _AppCalendarState();
}

class _AppCalendarState extends State<AppCalendar> {
  late DateTime _selected;
  late DateTime _displayedMonth;

  static DateTime _midnight(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  void initState() {
    super.initState();
    var selected = _midnight(widget.initialDate);
    if (selected.isBefore(widget.firstDate)) {
      selected = _midnight(widget.firstDate);
    } else if (selected.isAfter(widget.lastDate)) {
      selected = _midnight(widget.lastDate);
    }
    _selected = selected;
    _displayedMonth = DateTime(selected.year, selected.month);
  }

  bool get _canGoToPreviousMonth => _displayedMonth.isAfter(
    DateTime(widget.firstDate.year, widget.firstDate.month),
  );

  bool get _canGoToNextMonth => _displayedMonth.isBefore(
    DateTime(widget.lastDate.year, widget.lastDate.month),
  );

  void _goToPreviousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  void _select(DateTime date) => Navigator.of(context).pop(_midnight(date));

  @override
  Widget build(BuildContext context) {
    // Responsivo (Flutter Web): ocupa até 380px; em janelas estreitas,
    // encolhe até um mínimo usável sem estourar a viewport.
    final double width = math.max(
      304.0,
      math.min(_kCalendarWidth, MediaQuery.sizeOf(context).width - 32),
    );

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_kContainerRadius),
        boxShadow: const [
          BoxShadow(
            color: _kShadowColor,
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildWeekdayRow(),
            const SizedBox(height: 4),
            ..._buildWeekRows(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final title =
        '${_kMonthNames[_displayedMonth.month - 1]} de ${_displayedMonth.year}';
    return Row(
      children: [
        _NavButton(
          icon: Icons.chevron_left,
          tooltip: 'Mês anterior',
          onPressed: _canGoToPreviousMonth ? _goToPreviousMonth : null,
        ),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 32,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.6,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        _NavButton(
          icon: Icons.chevron_right,
          tooltip: 'Próximo mês',
          onPressed: _canGoToNextMonth ? _goToNextMonth : null,
        ),
      ],
    );
  }

  Widget _buildWeekdayRow() {
    return Semantics(
      header: true,
      child: Row(
        children: [
          for (final label in _kWeekdayLabels)
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 17 / 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Gera as semanas do mês exibido preenchendo a grade completa com dias
  /// dos meses adjacente (renderizados esmaecidos, sem interação).
  List<Widget> _buildWeekRows() {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingDays = _displayedMonth.weekday % 7; // domingo = 0
    final trailingDays =
        (7 - (leadingDays + daysInMonth) % 7) % 7;

    final cells = <DateTime>[
      for (var i = leadingDays; i > 0; i--)
        _displayedMonth.subtract(Duration(days: i)),
      for (var day = 1; day <= daysInMonth; day++)
        DateTime(year, month, day),
      for (var i = 1; i <= trailingDays; i++)
        DateTime(year, month + 1, i),
    ];

    return [
      for (var week = 0; week < cells.length ~/ 7; week++)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(child: _buildDayCell(cells[week * 7 + column])),
            ],
          ),
        ),
    ];
  }

  Widget _buildDayCell(DateTime date) {
    final bool inMonth =
        date.month == _displayedMonth.month && date.year == _displayedMonth.year;
    final bool enabled =
        !date.isBefore(widget.firstDate) && !date.isAfter(widget.lastDate);
    final bool isSelected = date == _selected;
    final bool isToday = date == _midnight(DateTime.now());

    Widget cell = SizedBox(
      height: _kTouchTarget,
      child: Center(
        child: Container(
          width: _kDayCircleSize,
          height: _kDayCircleSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? AppColors.primary : null,
            border: isSelected || !isToday
                ? null
                : Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
          ),
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 14,
              height: 18 / 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );

    if (!inMonth || !enabled) {
      // Dias de outros meses ou fora do intervalo: decorativos (opacity 0.3).
      cell = Opacity(opacity: 0.3, child: ExcludeSemantics(child: cell));
    } else {
      cell = Semantics(
        button: true,
        selected: isSelected,
        label:
            '${date.day} de ${_kMonthNames[date.month - 1]} de ${date.year}',
        child: cell,
      );
    }

    return InkWell(
      // Dias de outros meses são decorativos: navegação de mês somente
      // pelos botões ‹ › do header.
      onTap: enabled && inMonth ? () => _select(date) : null,
      customBorder: const CircleBorder(),
      child: cell,
    );
  }
}

/// Botão circular de navegação do header (‹ ›).
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.3,
        child: SizedBox(
          width: _kTouchTarget,
          height: _kTouchTarget,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: _kShadowColor,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Material(
                color: AppColors.surface,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  child: Icon(
                    icon,
                    size: 24,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
