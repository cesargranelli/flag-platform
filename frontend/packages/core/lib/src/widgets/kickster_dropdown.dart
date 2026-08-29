import 'package:flutter/material.dart';

import 'app_dropdown.dart';

/// Dropdown genérico no estilo do kit Kickster (issue #441).
///
/// Wrapper de `DropdownButtonFormField` sobre o tema (raio 16, preenchido
/// `surface`, rótulo sempre visível) — **não sobrescreve bordas**. Aceita
/// itens prontos ([items]) ou a forma declarativa [values] + [labels] (+
/// [icons] opcional); com ícones, os itens usam o `appDropdownItem` do core
/// (ícone à esquerda + rótulo com ellipsis).
class KicksterDropdown<T> extends StatelessWidget {
  const KicksterDropdown({
    super.key,
    required this.label,
    this.value,
    this.items,
    this.values,
    this.labels,
    this.icons,
    this.onChanged,
    this.hint,
    this.validator,
  }) : assert(
          (items != null && values == null && labels == null) ||
              (items == null && values != null && labels != null),
          'Informe `items` OU `values` + `labels` (+ `icons` opcional).',
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

  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, hintText: hint),
      items: items ?? _buildItems(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  List<DropdownMenuItem<T>> _buildItems() {
    return List.generate(values!.length, (i) {
      final icon = (icons != null && i < icons!.length) ? icons![i] : null;
      final label = i < labels!.length ? labels![i] : '${values![i]}';
      return DropdownMenuItem<T>(
        value: values![i],
        child: appDropdownItem(icon, label),
      );
    });
  }
}