import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

void main() {
  runApp(
    const ProviderScope(
      child: FlagPlatformApp(),
    ),
  );
}

class FlagPlatformApp extends StatelessWidget {
  const FlagPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flag Platform",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B3A6B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_football, size: 64, color: Color(0xFF1B3A6B)),
              SizedBox(height: 16),
              Text(
                "Flag Platform",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Em breve...",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
