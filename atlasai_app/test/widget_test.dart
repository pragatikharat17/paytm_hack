import 'package:flutter_test/flutter_test.dart';
import 'package:atlasai_app/main.dart';
import 'auth_test_support.dart';

void main() {
  testWidgets('Restored authentication opens the existing dashboard', (
    tester,
  ) async {
    final auth = TestAuthService(user: TestUser('persisted-user'));
    addTearDown(auth.controller.close);
    await tester.pumpWidget(AtlasAIApp(authService: auth));
    await tester.pump();
    expect(find.text('AtlasAI'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('AtlasAI Paytm'), findsOneWidget);
    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to AtlasAI'), findsOneWidget);
    expect(find.text('Payments & Support'), findsNothing);
  });
}
