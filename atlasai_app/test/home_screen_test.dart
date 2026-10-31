import 'package:atlasai_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 360.0, 600.0]) {
    testWidgets('Home actions fit a $width pixel viewport when offline', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('File Dispute'), findsOneWidget);
      expect(find.text('Voice Assistant'), findsOneWidget);
      expect(find.textContaining('Unable to connect.'), findsOneWidget);
      expect(find.textContaining('SocketException'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
