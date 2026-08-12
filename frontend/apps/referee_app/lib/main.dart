import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: FlagRefereeApp(),
    ),
  );
}

class FlagRefereeApp extends StatelessWidget {
  const FlagRefereeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flag Referee App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const RefereeHomeScreen(),
    );
  }
}

class RefereeHomeScreen extends StatelessWidget {
  const RefereeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Referee App')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_score, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Flag Platform',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Operacao de partidas pela mesa',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
