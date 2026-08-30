import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'kickster_field.dart';

/// Campo de formulário no estilo do kit Kickster (issue #436/#445).
///
/// Wrapper de `TextFormField` com `decoration` próprio do kit — raio 24
/// (pill), altura ~52px, fundo `surface`, borda `#DADADA` em repouso, rótulo
/// 14px SemiBold `grayLabel` quando não focado e ícones 18px `disabled` —
/// sem sobrescrever o `InputDecorationTheme` global. Aceita validação,
/// teclado tipado, autofill, ação de submissão, ícones de prefixo/sufixo
/// (ex.: olho de visibilidade de senha), máscara via [onChanged], limite de
/// caracteres, campos somente leitura (ex.: datas com picker) e um [prefix]
/// arbitrário (ex.: seletor de cor).
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
    this.hintText,
    this.onChanged,
    this.maxLength,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
    this.textCapitalization,
    this.prefix,
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

  /// Texto de dica exibido dentro do campo enquanto vazio (ex.: máscara).
  final String? hintText;

  /// Notifica a cada digitação (ex.: máscara CPF/CNPJ/telefone).
  final ValueChanged<String>? onChanged;

  /// Limite de caracteres com contador (padrão do `TextFormField`).
  final int? maxLength;

  /// Linhas visíveis do campo; `null` cresce com o conteúdo.
  final int? maxLines;

  /// Campo somente leitura (ex.: data preenchida via picker).
  final bool readOnly;

  /// Ação ao tocar no campo (usado com [readOnly] para abrir o picker).
  final VoidCallback? onTap;

  /// Formatters de entrada (ex.: `FilteringTextInputFormatter.digitsOnly`).
  final List<TextInputFormatter>? inputFormatters;

  /// Capitalização de texto (ex.: sentenças para nomes).
  final TextCapitalization? textCapitalization;

  /// Prefixo arbitrário (Widget) — substitui [prefixIcon].
  final Widget? prefix;

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
      onChanged: onChanged,
      maxLength: maxLength,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      decoration: kicksterFieldDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        prefix: prefix,
      ),
    );
  }
}
