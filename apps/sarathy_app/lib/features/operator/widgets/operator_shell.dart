import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services.dart';

/// Shared navigation shell for the five operator screens.
///
/// One [Scaffold] with an AppBar, a sign-out button, and a bottom
/// [NavigationBar] so every operator screen keeps a consistent chrome instead
/// of owning its own Scaffold/AppBar.
class OperatorShell extends StatelessWidget {
  /// The body content of the current operator screen.
  final Widget child;

  /// The current route path. Derives the AppBar title and selected index.
  final String currentPath;

  /// Optional sign-out handler. When omitted, [AuthService.logout] is used and
  /// the router navigates to the operator login route.
  final Future<void> Function()? onLogout;

  const OperatorShell({
    super.key,
    required this.child,
    required this.currentPath,
    this.onLogout,
  });

  static const List<String> _routeNames = [
    'operatorDashboard',
    'operatorTrips',
    'operatorFleet',
    'operatorRoutes',
    'operatorIncidents',
  ];

  static const List<String> _titles = [
    'Dashboard',
    'Live Trips',
    'Fleet',
    'Routes & Stops',
    'Incidents',
  ];

  static const List<IconData> _icons = [
    Icons.dashboard,
    Icons.near_me,
    Icons.directions_bus,
    Icons.route,
    Icons.report_problem,
  ];

  /// Index of [path] within the operator destinations (0..4).
  ///
  /// Pure and testable. Returns 0 for unknown paths.
  static int indexForPath(String path) {
    switch (path) {
      case '/operator/dashboard':
        return 0;
      case '/operator/trips':
        return 1;
      case '/operator/fleet':
        return 2;
      case '/operator/routes':
        return 3;
      case '/operator/incidents':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = indexForPath(currentPath);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              await _handleSignOut(context);
            },
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == selectedIndex) return;
          context.goNamed(_routeNames[index]);
        },
        destinations: List.generate(
          _titles.length,
          (index) => NavigationDestination(
            icon: Icon(_icons[index]),
            label: _titles[index],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    if (onLogout != null) {
      await onLogout!();
      return;
    }
    await AuthService.logout();
    if (context.mounted) context.goNamed('operatorLogin');
  }
}
