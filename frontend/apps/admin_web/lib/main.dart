import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'src/app.dart';

void main() {
  // URLs reais no browser (/organizations/new em vez de /#/organizations/new).
  usePathUrlStrategy();
  runApp(
    const ProviderScope(
      child: FlagAdminWeb(),
    ),
  );
}
