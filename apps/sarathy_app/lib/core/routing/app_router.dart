import 'package:go_router/go_router.dart';
import '../../../features.dart';

/// Centralized routing configuration for the Sarathy app.
/// Uses go_router for declarative, type-safe navigation.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Entry point - role selection
      GoRoute(
        path: '/',
        name: 'roleSelection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/login/operator',
        name: 'operatorLogin',
        builder: (context, state) => const OperatorLoginScreen(),
      ),
      GoRoute(
        path: '/login/crew',
        name: 'crewLogin',
        builder: (context, state) => const CrewLoginScreen(),
      ),

      // Passenger routes (public/unauthenticated)
      GoRoute(
        path: '/passenger/home',
        name: 'passengerHome',
        builder: (context, state) => const PassengerHomeScreen(),
      ),
      GoRoute(
        path: '/passenger/tracking/:tripId',
        name: 'passengerTracking',
        builder: (context, state) {
          final tripId = int.parse(state.pathParameters['tripId']!);
          final stopName = state.uri.queryParameters['stopName'] ?? 'Stop';
          return LiveTrackingScreen(tripId: tripId, stopName: stopName);
        },
      ),

      // Crew routes (require crew auth)
      GoRoute(
        path: '/crew/trip-control',
        name: 'crewTripControl',
        builder: (context, state) => const CrewTripControlScreen(),
      ),

      // Operator routes (require operator auth)
      GoRoute(
        path: '/operator/dashboard',
        name: 'operatorDashboard',
        builder: (context, state) => const OperatorDashboardScreen(),
      ),
      GoRoute(
        path: '/operator/fleet',
        name: 'operatorFleet',
        builder: (context, state) => const OperatorFleetScreen(),
      ),
      GoRoute(
        path: '/operator/routes',
        name: 'operatorRoutes',
        builder: (context, state) => const OperatorRoutesScreen(),
      ),
      GoRoute(
        path: '/operator/trips',
        name: 'operatorTrips',
        builder: (context, state) => const OperatorTripsScreen(),
      ),
      GoRoute(
        path: '/operator/incidents',
        name: 'operatorIncidents',
        builder: (context, state) => const OperatorIncidentsScreen(),
      ),
    ],
  );
}