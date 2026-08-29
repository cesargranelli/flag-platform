import 'package:flutter/material.dart';

import 'kickster_field.dart';

/// Campo de formulário no estilo do kit Kickster (issue #436/#445).
///
/// Wrapper de `TextFormField` com `decoration` próprio do kit — raio 24
/// (pill), altura ~52px, fundo `surface`, borda `#DADADA` em repouso, rótulo
/// 14px SemiBold `grayLabel` quando não focado e ícones 18px `disabled` —
/// sem sobrescrever o `InputDecorationTheme` global. Aceita validação,
/// teclado tipado, autofill, ação de submissão e ícones de prefixo/sufixo
/// (ex.: olho de visibilidade de senha).
class KicksterInput extends StatelessWidget {
  const KicksterInput({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.autofillHints,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      enabled: enabled,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: kicksterFieldDecoration(
        labelText: label,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
