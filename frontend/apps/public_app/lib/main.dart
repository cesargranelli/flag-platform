import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Semeia o "campeonato em foco" persistido para o shell decidir a aba
  // Campeonato já no primeiro frame (sem esperar um rebuild assíncrono).
  final initialFocus = seedFocusedCompetition(prefs);

  runApp(
    ProviderScope(
      overrides: [
        focusedCompetitionProvider.overrideWith(
          () => FocusedCompetitionNotifier(initial: initialFocus),
        ),
      ],
      child: const FlagPublicApp(),
    ),
  );
}
