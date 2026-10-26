import 'package:flutter/material.dart';
import 'core/routing/app_router.dart';
import 'main.dart' hide main;
import 'services/auth/auth_service.dart';

/// Crew entrypoint.
///
/// Initializes the crew session from secure storage before running the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initializeCrewSession();
  runApp(const SarathyApp(flavor: AppFlavor.crew));
}
