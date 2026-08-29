import 'package:flutter/material.dart';

/// Shell do Admin Web — sem header fixo, cada tela gerencia seu próprio layout.
class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.navigationShell,
  });

  final Widget navigationShell;

  @override
  Widget build(BuildContext context) => navigationShell;
}
