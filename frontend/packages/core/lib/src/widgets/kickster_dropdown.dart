import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_dropdown.dart';

/// Dropdown no estilo do kit Kickster (issues #441/#445/#451).
///
/// Menu customizado — o `DropdownButtonFormField` padrão do Flutter não
/// permite o estilo de lista do kit (itens com checkbox + divisores). O
/// campo fechado é um pill de 52px com raio 24 e fundo `#F6F8FE`
/// ([AppColors.surfaceMuted]); a lista aberta é um **container único
/// segmentado** (itens juntos, divididos por `Divider` `#E3E7EC`).
///
/// Medidas EXATAS do Figma (node `30020:3316` aberto):
/// - **Campo fechado**: 327×52, raio 24, fundo `#F6F8FE`, valor 12px
///   Regular `#9CA4AB`, seta 24×24 `#9CA4AB` à direita.
/// - **Lista aberta**: container único 327×N, raio **12**, fundo `surface`,
///   borda `line` 1px (`#E3E7EC`); itens de 48px sem espaço entre si, com
///   `Divider` 1px `line` entre eles; **selecionado** = checkbox circular
///   marcado (24px primary + check branco) à direita + texto `#111111`;
///   **não selecionado** = checkbox vazio (borda `#E3E9ED`).
///
/// Mantém a API migrada: aceita itens prontos ([items]) ou a forma
/// declarativa [values] + [labels] (+ [icons] opcional); com ícones, os
/// itens usam o `appDropdownItem` do core (ícone à esquerda + rótulo).
///
/// Implementado como `FormField` (herda validação, erro e `didChange`):
/// o rótulo fica acima do pill, o valor exibido usa o texto da opção
/// selecionada (ou [hint]) em 12px `#9CA4AB`, e o menu abre via
/// `showGeneralDialog` ancorado abaixo do campo (toque fora fecha).
class KicksterDropdown<T> extends FormField<T> {
  KicksterDropdown({
    super.key,
    required this.label,
    this.value,
    this.items,
    this.values,
    this.labels,
    this.icons,
    this.onChanged,
    this.hint,
    this.helperText,
    super.validator,
  }) : assert(
          (items != null && values == null && labels == null) ||
              (items == null && values != null && labels != null),
          'Informe `items` OU `values` + `labels` (+ `icons` opcional).',
        ),
        super(
          initialValue: value,
          builder: (field) =>
              (field as _KicksterDropdownState<T>)._buildContent(),
        );

  final String label;

  /// Valor inicial selecionado.
  final T? value;

  /// Itens prontos (forma avançada — substitui [values]/[labels]/[icons]).
  final List<DropdownMenuItem<T>>? items;

  /// Valores das opções (forma declarativa, com [labels]).
  final List<T>? values;

  /// Rótulos das opções (paralelo a [values]).
  final List<String>? labels;

  /// Ícones por opção (paralelo a [values], itens podem ser `null`).
  final List<IconData?>? icons;

  final ValueChanged<T?>? onChanged;

  /// Texto de dica exibido quando nada está selecionado.
  final String? hint;

  /// Texto de ajuda abaixo do campo (mantém `helperText` dos formulários
  /// nativos migrados, ex.: descrição das opções).
  final String? helperText;

  @override
  FormFieldState<T> createState() => _KicksterDropdownState<T>();
}

/// Estado do [KicksterDropdown] — herda o ciclo de validação do `FormField`
/// ([FormFieldState.errorText], [FormFieldState.didChange]).
class _KicksterDropdownState<T> extends FormFieldState<T> {
  final GlobalKey _pillKey = GlobalKey();

  bool _menuOpen = false;

  KicksterDropdown<T> get _widget => widget as KicksterDropdown<T>;

  /// Normaliza as opções para [_KicksterMenuEntry], seja pela forma
  /// declarativa (values/labels/icons) ou por [items] (child já montado).
  List<_KicksterMenuEntry<T>> get _entries {
    final items = _widget.items;
    if (items != null) {
      return [
        for (final item in items)
          _KicksterMenuEntry<T>(
            value: item.value,
            child: item.child,
            labelText: _extractText(item.child),
          ),
      ];
    }
    final values = _widget.values!;
    final labels = _widget.labels!;
    final icons = _widget.icons;
    return List.generate(values.length, (i) {
      final icon = (icons != null && i < icons.length) ? icons[i] : null;
      final label = i < labels.length ? labels[i] : '${values[i]}';
      return _KicksterMenuEntry<T>(
        value: values[i],
        child: appDropdownItem(icon, label),
        labelText: label,
      );
    });
  }

  /// Opção correspondente ao valor atual ([FormFieldState.value]).
  _KicksterMenuEntry<T>? get _selectedEntry {
    final current = value;
    for (final entry in _entries) {
      if (entry.value == current) return entry;
    }
    return null;
  }

  /// Corpo do campo: rótulo (se informado) + pill + erro/helper.
  Widget _buildContent() {
    final errorText = this.errorText;
    final label = _widget.label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: AppTextStyles.paragraph.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.grayLabel,
            ),
          ),
          const SizedBox(height: 6),
        ],
        _buildPill(),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: AppTextStyles.fieldLabel.copyWith(color: AppColors.danger),
          ),
        ],
        if (_widget.helperText != null && errorText == null) ...[
          const SizedBox(height: 6),
          Text(
            _widget.helperText!,
            style: AppTextStyles.fieldLabel.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  /// Campo fechado: pill 52px, raio 24, fundo `#F6F8FE`.
  Widget _buildPill() {
    return Semantics(
      button: true,
      label: _pillSemanticsLabel(),
      hint: 'Abrir opções',
      child: Container(
        key: _pillKey,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(24),
          border: _menuOpen
              ? Border.all(color: AppColors.primary, width: 2)
              : hasError
                  ? Border.all(color: AppColors.danger, width: 1)
                  : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: _openMenu,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _buildValue()),
                  const SizedBox(width: 8),
                  // Kit: arrow-ios-downward 24×24 `#9CA4AB` à direita.
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 24,
                    color: AppColors.disabled,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Valor exibido no campo fechado: texto da opção selecionada (ou o
  /// [hint]) em 12px `#9CA4AB` — no kit o valor aparece em cinza.
  Widget _buildValue() {
    final text = _selectedEntry?.labelText ?? _widget.hint;
    if (text == null) return const SizedBox.shrink();
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 12,
        height: 20 / 12,
        fontWeight: FontWeight.w400,
        color: AppColors.disabled,
      ),
    );
  }

  String _pillSemanticsLabel() {
    final label = _widget.label;
    final valueText = _selectedEntry?.labelText ?? _widget.hint;
    return valueText == null ? label : '$label: $valueText';
  }

  /// Abre o menu posicionado logo abaixo do pill ([showGeneralDialog]).
  Future<void> _openMenu() async {
    final pillContext = _pillKey.currentContext;
    if (pillContext == null) return;
    final renderBox = pillContext.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    setState(() => _menuOpen = true);
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _KicksterMenuOverlay<T>(
          anchorOffset: offset,
          anchorWidth: size.width,
          anchorBottom: offset.dy + size.height,
          entries: _entries,
          selectedValue: value,
          onSelect: (selected) {
            Navigator.of(dialogContext).pop();
            _selectValue(selected);
          },
        );
      },
    );
    if (mounted) setState(() => _menuOpen = false);
  }

  /// Seleciona uma opção: atualiza o estado do `FormField` (validação) e
  /// notifica o chamador ([KicksterDropdown.onChanged]).
  void _selectValue(T? selected) {
    didChange(selected);
    _widget.onChanged?.call(selected);
  }
}

/// Entrada normalizada do menu do dropdown.
class _KicksterMenuEntry<T> {
  const _KicksterMenuEntry({
    required this.value,
    required this.child,
    required this.labelText,
  });

  final T? value;
  final Widget child;
  final String? labelText;
}

/// Overlay do menu aberto: container único segmentado sob o campo (modelo
/// do kit, node `30020:3316`) — raio 12, fundo `surface`, borda `line` e
/// itens juntos com divisores internos.
class _KicksterMenuOverlay<T> extends StatelessWidget {
  const _KicksterMenuOverlay({
    required this.anchorOffset,
    required this.anchorWidth,
    required this.anchorBottom,
    required this.entries,
    required this.selectedValue,
    required this.onSelect,
  });

  final Offset anchorOffset;
  final double anchorWidth;
  final double anchorBottom;
  final List<_KicksterMenuEntry<T>> entries;
  final T? selectedValue;
  final ValueChanged<T?> onSelect;

  /// Altura máxima da lista: 6 itens de 48px + 5 divisores de 1px + bordas.
  static const double _maxMenuHeight = 6 * 48 + 5 * 1 + 2;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned(
            left: anchorOffset.dx,
            top: anchorBottom + 8,
            width: anchorWidth,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: _maxMenuHeight),
              child: SingleChildScrollView(
                // Container único com divisores internos (sem pills/gap).
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < entries.length; i++) ...[
                        _KicksterMenuItem<T>(
                          entry: entries[i],
                          selected: entries[i].value == selectedValue,
                          onTap: () => onSelect(entries[i].value),
                        ),
                        if (i < entries.length - 1)
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.line,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Item do menu aberto: linha de 48px dentro do container segmentado, com
/// o checkbox circular à direita como destaque do selecionado (o item em si
/// não tem borda — os cantos são clippados pelo container pai).
class _KicksterMenuItem<T> extends StatelessWidget {
  const _KicksterMenuItem({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final _KicksterMenuEntry<T> entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: entry.labelText,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 12,
                      height: 20 / 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.black,
                    ),
                    child: entry.child,
                  ),
                ),
                const SizedBox(width: 12),
                _KicksterCheckCircle(checked: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Checkbox circular do kit (24px, sem alvo de toque próprio — o item do
/// menu é o alvo): marcado = fundo `primary` + check branco; vazio = borda
/// `#E3E9ED` ([AppColors.fieldBorderLight]).
class _KicksterCheckCircle extends StatelessWidget {
  const _KicksterCheckCircle({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? AppColors.primary : null,
        border: Border.all(
          color: checked ? AppColors.primary : AppColors.fieldBorderLight,
          width: 1,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 16, color: AppColors.background)
          : null,
    );
  }
}

/// Extrai o texto de um widget de item para exibição/acessibilidade
/// (cobre `Text`, `RichText` e wrappers comuns, ex.: `appDropdownItem`).
String? _extractText(Widget? widget) {
  if (widget == null) return null;
  if (widget is Text) {
    return widget.data ?? widget.textSpan?.toPlainText();
  }
  if (widget is RichText) {
    return widget.text.toPlainText();
  }
  if (widget is Padding) return _extractText(widget.child);
  if (widget is Align) return _extractText(widget.child);
  if (widget is Center) return _extractText(widget.child);
  if (widget is DefaultTextStyle) return _extractText(widget.child);
  if (widget is Flexible) return _extractText(widget.child);
  if (widget is Semantics) return _extractText(widget.child);
  if (widget is Row) {
    for (final child in widget.children) {
      final text = _extractText(child);
      if (text != null && text.isNotEmpty) return text;
    }
  }
  if (widget is Column) {
    for (final child in widget.children) {
      final text = _extractText(child);
      if (text != null && text.isNotEmpty) return text;
    }
  }
  return null;
}