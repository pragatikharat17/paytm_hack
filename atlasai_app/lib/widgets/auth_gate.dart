import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/splash_screen.dart';

class AuthGate extends StatefulWidget {
  final AuthService? service;
  const AuthGate({super.key, this.service});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final service = widget.service ?? AuthService.instance;
  late final Stream<User?> changes = service.authStateChanges();
  @override
  Widget build(BuildContext context) => AuthScope(
    service: service,
    child: StreamBuilder<User?>(
      stream: changes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Unable to restore your session. Please restart the app.',
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Discard the entire private route stack on logout or account change.
        return _SessionNavigator(
          key: ValueKey(snapshot.data?.uid ?? 'signed-out'),
          signedIn: snapshot.data != null,
        );
      },
    ),
  );
}

class _SessionNavigator extends StatefulWidget {
  final bool signedIn;
  const _SessionNavigator({super.key, required this.signedIn});
  @override
  State<_SessionNavigator> createState() => _SessionNavigatorState();
}

class _SessionNavigatorState extends State<_SessionNavigator> {
  final _navigator = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) => NavigatorPopHandler<Object?>(
    onPopWithResult: (result) => _navigator.currentState!.pop(result),
    child: Navigator(
      key: _navigator,
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) =>
            widget.signedIn ? const SplashScreen() : const LoginScreen(),
      ),
    ),
  );
}
