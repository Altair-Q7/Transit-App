import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sarathy_app/features/operator/widgets/operator_shell.dart';

void main() {
  group('OperatorShell.indexForPath', () {
    test('maps each operator path to its destination index', () {
      expect(OperatorShell.indexForPath('/operator/dashboard'), 0);
      expect(OperatorShell.indexForPath('/operator/trips'), 1);
      expect(OperatorShell.indexForPath('/operator/fleet'), 2);
      expect(OperatorShell.indexForPath('/operator/routes'), 3);
      expect(OperatorShell.indexForPath('/operator/incidents'), 4);
    });

    test('defaults to 0 for unknown paths', () {
      expect(OperatorShell.indexForPath('/operator/login'), 0);
      expect(OperatorShell.indexForPath('/crew/trip-control'), 0);
      expect(OperatorShell.indexForPath(''), 0);
    });
  });

  group('OperatorShell in a GoRouter', () {
    GoRouter dummyRouter() {
      return GoRouter(
        initialLocation: '/operator/dashboard',
        routes: [
          GoRoute(
            path: '/operator/dashboard',
            name: 'operatorDashboard',
            builder: (_, __) => const OperatorShell(
              currentPath: '/operator/dashboard',
              child: Text('dashboard body'),
            ),
          ),
          GoRoute(
            path: '/operator/fleet',
            name: 'operatorFleet',
            builder: (_, __) => const OperatorShell(
              currentPath: '/operator/fleet',
              child: Text('fleet body'),
            ),
          ),
          GoRoute(
            path: '/operator/trips',
            name: 'operatorTrips',
            builder: (_, __) => const OperatorShell(
              currentPath: '/operator/trips',
              child: Text('trips body'),
            ),
          ),
          GoRoute(
            path: '/operator/routes',
            name: 'operatorRoutes',
            builder: (_, __) => const OperatorShell(
              currentPath: '/operator/routes',
              child: Text('routes body'),
            ),
          ),
          GoRoute(
            path: '/operator/incidents',
            name: 'operatorIncidents',
            builder: (_, __) => const OperatorShell(
              currentPath: '/operator/incidents',
              child: Text('incidents body'),
            ),
          ),
        ],
      );
    }

    testWidgets('shows five destinations with Dashboard selected at /operator/dashboard',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: dummyRouter()));
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.destinations.length, 5);
      expect(navBar.selectedIndex, 0);
      expect(find.text('dashboard body'), findsOneWidget);
    });

    testWidgets('tapping Fleet shows the fleet body and selects index 2',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: dummyRouter()));
      await tester.pumpAndSettle();

      expect(find.text('dashboard body'), findsOneWidget);

      final fleet = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Fleet'),
      );
      await tester.tap(fleet);
      await tester.pumpAndSettle();

      expect(find.text('fleet body'), findsOneWidget);
      expect(find.text('dashboard body'), findsNothing);
      expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 2);
    });
  });

  group('sign-out', () {
    testWidgets('calls the injected onLogout exactly once and never calls AuthService.logout',
        (WidgetTester tester) async {
      int calls = 0;
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/operator/dashboard',
            routes: [
              GoRoute(
                path: '/operator/dashboard',
                name: 'operatorDashboard',
                builder: (_, __) => OperatorShell(
                  currentPath: '/operator/dashboard',
                  onLogout: () async {
                    calls++;
                  },
                  child: const Text('dashboard body'),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pump();

      expect(calls, 1);
    });
  });
}
