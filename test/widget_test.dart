import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_demo/main.dart';

void main() {
  testWidgets('Counter increments when the button is tapped',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SimpleDemoApp());

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
