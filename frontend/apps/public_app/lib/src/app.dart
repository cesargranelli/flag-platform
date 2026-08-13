import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';

import 'router/app_router.dart';

/// Widget raiz do Public App.
class FlagPublicApp extends StatelessWidget {
  const FlagPublicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flag Public App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.build(),
    );
  }
}
