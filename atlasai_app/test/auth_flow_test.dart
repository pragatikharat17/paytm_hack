import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasai_app/main.dart';
import 'auth_test_support.dart';

void main() {
  Future<TestAuthService> start(WidgetTester tester) async {
    final auth = TestAuthService();
    addTearDown(auth.controller.close);
    await tester.pumpWidget(AtlasAIApp(authService: auth));
    await tester.pumpAndSettle();
    return auth;
  }

  Future<void> fill(
    WidgetTester tester, {
    String password = 'password123',
  }) async {
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'customer@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), password);
  }

  testWidgets('Login errors, password visibility and successful login', (
    tester,
  ) async {
    final auth = await start(tester);
    await fill(tester);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(find.byTooltip('Hide password'), findsOneWidget);
    auth.failure = FirebaseAuthException(code: 'invalid-credential');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('The email or password is incorrect.'), findsOneWidget);
    auth.failure = null;
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Payments & Support'), findsOneWidget);
  });
  testWidgets(
    'Registration validates fields and opens the unchanged dashboard',
    (tester) async {
      final auth = await start(tester);
      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
      await tester.pumpAndSettle();
      expect(auth.registrations, 0);
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      await fill(tester, password: 'short');
      await tester.enterText(find.byType(TextFormField).at(2), 'different');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(find.text('Passwords do not match.'), findsOneWidget);
      await fill(tester);
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(auth.registrations, 1);
      expect(find.text('Payments & Support'), findsOneWidget);
    },
  );
  testWidgets('Password reset sends email and allows return to login', (
    tester,
  ) async {
    final auth = await start(tester);
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'customer@example.com');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(auth.resets, 1);
    expect(find.textContaining('a reset link has been sent'), findsOneWidget);
    await tester.tap(find.text('Back to sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to AtlasAI'), findsOneWidget);
  });
  testWidgets('Sign out discards nested private screens', (tester) async {
    final auth = TestAuthService(user: TestUser('test-user'));
    addTearDown(auth.controller.close);
    await tester.pumpWidget(AtlasAIApp(authService: auth));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('File Dispute'));
    await tester.pumpAndSettle();
    auth.emit(null);
    await tester.pumpAndSettle();
    expect(find.text('Welcome to AtlasAI'), findsOneWidget);
    expect(find.text('AtlasAI Teammate'), findsNothing);
  });
}
