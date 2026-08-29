import 'dart:async';

import 'package:flutter/material.dart';

import 'kickster_input.dart';

/// Campo de busca no estilo do kit Kickster (issue #455).
///
/// Pill de 52px com raio 24 (mesma decoração de [KicksterInput]), ícone de
/// lupa 18px à esquerda, hint "Buscar..." e botão de limpar quando há texto.
/// Dispara [onChanged] com [debounce] (300ms por padrão) para filtrar
/// listagens sem re-render a cada tecla.
class KicksterSearchField extends StatefulWidget {
  const KicksterSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Buscar...',
    this.debounce = const Duration(milliseconds: 300),
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final Duration debounce;

  @override
  State<KicksterSearchField> createState() => _KicksterSearchFieldState();
}

class _KicksterSearchFieldState extends State<KicksterSearchField> {
  Timer? _debounce;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () => widget.onChanged(value));
  }

  void _clear() {
    widget.controller.clear();
    _debounce?.cancel();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return KicksterInput(
      label: '',
      controller: widget.controller,
      hintText: widget.hint,
      prefixIcon: Icons.search,
      onChanged: _onChanged,
      suffixIcon: _hasText
          ? IconButton(
              tooltip: 'Limpar busca',
              icon: const Icon(Icons.close, size: 18),
              onPressed: _clear,
            )
          : null,
    );
  }
}