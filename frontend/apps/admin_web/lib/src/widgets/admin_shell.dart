import 'package:flutter/material.dart';

/// Shell do Admin Web — sem header fixo, cada tela gerencia seu próprio layout.
///
/// Mantém um `Scaffold` como ancestral de Material/ScaffoldMessenger para as
/// telas autenticadas (o `AppScreen` de cada tela é uma `Column`, não um
/// Scaffold). Sem ele, `SnackBar`s não aparecem e widgets que exigem
/// `Material` (ex.: `TextFormField`, `IconButton`, `PopupMenuButton`) podem
/// lançar "No Material widget found" (regressão #457).
class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.navigationShell,
  });

  final Widget navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
    );
  }
}