import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'widgets/auth_gate.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(const AtlasAIApp());
}

class AtlasAIApp extends StatelessWidget {
  final AuthService? authService;
  const AtlasAIApp({super.key, this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AtlasAI — Autonomous Customer Resolution Teammate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AuthGate(service: authService),
    );
  }
}
