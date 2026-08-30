import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'src/app.dart';

void main() {
  // Captura assertions do SDK que travam o frame no debug web
  // (mouse_tracker _debugDuringDeviceUpdate — flutter#137599).
  // Sem esse handler, a assertion lança durante frame callback e
  // resulta em tela branca. Em release os asserts são removidos.
  FlutterError.onError = (details) {
    final msg = details.exception.toString();
    if (msg.contains('_debugDuringDeviceUpdate')) {
      debugPrint('[sdk-bug] mouse_tracker assertion ignorada: $msg');
      return; // ignora — frame recuperável
    }
    FlutterError.presentError(details);
  };

  // URLs reais no browser (/organizations/new em vez de /#/organizations/new).
  usePathUrlStrategy();
  runApp(
    const ProviderScope(
      child: FlagAdminWeb(),
    ),
  );
}
