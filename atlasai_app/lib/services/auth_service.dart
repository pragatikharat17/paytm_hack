import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class AuthService {
  static final instance = AuthService();
  FirebaseAuth get _auth => FirebaseAuth.instance;
  Stream<User?> authStateChanges() => _auth.authStateChanges();
  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
  Future<void> signOut() => _auth.signOut();
  Future<String> idToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'requires-recent-login');
    }
    final token = await user.getIdToken(forceRefresh);
    if (token == null) {
      throw FirebaseAuthException(code: 'requires-recent-login');
    }
    return token;
  }

  static String errorMessage(Object error) {
    if (error is! FirebaseAuthException) {
      return 'Something went wrong. Please try again.';
    }
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'The email or password is incorrect.',
      'email-already-in-use' =>
        'An account already exists with this email. Please sign in.',
      'invalid-email' => 'Enter a valid email address.',
      'weak-password' =>
        'Choose a stronger password with at least 8 characters.',
      'network-request-failed' => 'Check your connection and try again.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'user-disabled' => 'This account has been disabled. Contact support.',
      'operation-not-allowed' =>
        'Email sign-in is not available. Contact support.',
      'requires-recent-login' ||
      'user-token-expired' ||
      'invalid-user-token' => 'Your session has expired. Please sign in again.',
      _ => 'Unable to complete authentication. Please try again.',
    };
  }
}

class AuthScope extends InheritedWidget {
  final AuthService service;
  const AuthScope({super.key, required this.service, required super.child});
  static AuthService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.service ??
      AuthService.instance;
  @override
  bool updateShouldNotify(AuthScope oldWidget) => oldWidget.service != service;
}
