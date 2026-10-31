import 'package:flutter_test/flutter_test.dart';
import 'package:atlasai_app/main.dart';

void main() {
  testWidgets('AtlasAI app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AtlasAIApp());
    expect(find.text('AtlasAI'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('AtlasAI Paytm'), findsOneWidget);
  });
}
