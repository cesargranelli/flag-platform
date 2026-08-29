import 'package:flutter/material.dart';

/// Campo de formulário no estilo do kit Kickster (issue #436).
///
/// Wrapper de `TextFormField` sobre o `InputDecorationTheme` do tema (raio
/// 16, preenchido `surface`, rótulo sempre visível) — **não sobrescreve
/// bordas nem estilos**. Aceita validação e teclado tipado.
class KicksterInput extends StatelessWidget {
  const KicksterInput({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
    this.prefixIcon,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      ),
    );
  }
}