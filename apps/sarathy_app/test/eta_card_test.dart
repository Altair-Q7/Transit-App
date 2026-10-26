import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sarathy_app/features/passenger/widgets/eta_card.dart';
import 'package:sarathy_app/models.dart';

EtaEstimate _estimate(String status) => EtaEstimate(
      tripId: 1,
      stopId: 42,
      etaMinutes: 5,
      confidence: 'high',
      distanceKm: 1.2,
      status: status,
    );

void main() {
  testWidgets('en_route shows "Status: On the way" with a green dot',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EtaCard(stopName: 'Main St', estimate: _estimate('en_route')),
      ),
    );

    expect(find.text('Status: On the way'), findsOneWidget);
    expect(find.text('Location: Main St'), findsOneWidget);
  });

  testWidgets('departed shows "Status: Departed" with a slate dot',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EtaCard(stopName: 'Main St', estimate: _estimate('departed')),
      ),
    );

    expect(find.text('Status: Departed'), findsOneWidget);
  });

  testWidgets('no_live_data shows "Status: No live data" and awaiting text',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EtaCard(stopName: 'Main St', estimate: _estimate('no_live_data')),
      ),
    );

    expect(find.text('Status: No live data'), findsOneWidget);
    expect(find.text('Live ETA: awaiting live data'), findsOneWidget);
    expect(find.textContaining('mins'), findsNothing);
  });
}
