import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_dropdown.dart';
import 'kickster_menu_anchor.dart';

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
/// [KicksterMenuAnchor] (toque fora, Esc e seleção fecham; teclado
/// ↑/↓/Enter navega os itens).
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
  /// Altura máxima da lista aberta: 6 itens de 48px + 5 divisores de 1px +
  /// bordas (limite do overlay antigo, aplicado via
  /// [KicksterMenuAnchor.maxHeight]).
  static const double _maxMenuHeight = 6 * 48 + 5 * 1 + 2;

  /// `true` enquanto o menu está aberto (borda `primary` no pill).
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
              // Contraste do rótulo: `textSecondary` (#66707A) sobre o
              // fundo claro mantém 4.6:1 (AA) — `grayLabel` ficava em 3.9:1.
              color: AppColors.textSecondary,
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

  /// Campo fechado: pill 52px, raio 24, fundo `#F6F8FE`, envolvido no
  /// [KicksterMenuAnchor] (toque, foco por Tab e menu com ↑/↓/Enter/Esc).
  Widget _buildPill() {
    final entries = _entries;
    return LayoutBuilder(
      builder: (context, constraints) {
        return KicksterMenuAnchor(
          triggerLabel: _pillSemanticsLabel(),
          // Largura do menu = largura do campo (o overlay antigo media o
          // pill via GlobalKey; aqui o pill estica com o `stretch` do pai).
          width: constraints.maxWidth,
          maxHeight: _maxMenuHeight,
          onOpenChanged: (open) {
            if (mounted) setState(() => _menuOpen = open);
          },
          trigger: Container(
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
          items: [
            for (var i = 0; i < entries.length; i++)
              KicksterMenuItem(
                // O anchor insere o `Divider` entre os itens; aqui fica a
                // linha de 48px com o conteúdo + checkbox circular à direita.
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
                        child: entries[i].child,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Semantics(
                      selected: entries[i].value == value,
                      child: _KicksterCheckCircle(
                        checked: entries[i].value == value,
                      ),
                    ),
                  ],
                ),
                onTap: () => _selectValue(entries[i].value),
              ),
          ],
        );
      },
    );
  }

  /// Valor exibido no campo fechado: texto da opção selecionada em 14px w500
  /// `textPrimary` (contraste ≥4.5:1 — o antigo 12px `#9CA4AB` ficava em
  /// 2.4:1) ou o [hint] em `textSecondary` (4.6:1) quando nada está
  /// selecionado.
  Widget _buildValue() {
    final selected = _selectedEntry;
    final text = selected?.labelText ?? _widget.hint;
    if (text == null) return const SizedBox.shrink();
    final style = selected != null
        ? const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          )
        : AppTextStyles.fieldLabel.copyWith(color: AppColors.textSecondary);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }

  String _pillSemanticsLabel() {
    final label = _widget.label;
    final valueText = _selectedEntry?.labelText ?? _widget.hint;
    return valueText == null ? label : '$label: $valueText';
  }

  /// Seleciona uma opção: atualiza o estado do `FormField` (validação) e
  /// notifica o chamador ([KicksterDropdown.onChanged]). O menu já foi
  /// fechado pelo [KicksterMenuAnchor] antes do `onTap` do item.
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