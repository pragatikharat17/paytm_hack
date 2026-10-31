import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AtlasAIApp());
}

class AtlasAIApp extends StatelessWidget {
  const AtlasAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AtlasAI — Autonomous Customer Resolution Teammate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}
