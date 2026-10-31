import 'package:atlasai_app/screens/ai_assistant_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 360.0, 600.0]) {
    testWidgets('Assistant header fits $width pixels with a back button', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AIAssistantScreen(),
                  ),
                ),
                child: const Text('Open'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.textContaining('**AtlasAI**'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Language: English'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<String>, 'मराठी (Marathi)'),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Language: मराठी (Marathi)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
