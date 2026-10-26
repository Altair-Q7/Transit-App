// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sarathy_app/features/shared/screens/role_selection_screen.dart';

void main() {
  testWidgets('role selection shows all supported roles', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RoleSelectionScreen()));

    expect(find.text('Passenger'), findsOneWidget);
    expect(find.text('Crew'), findsOneWidget);
    expect(find.text('Operator'), findsOneWidget);
  });
}
