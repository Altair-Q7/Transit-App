import 'package:flutter/material.dart';
import 'core/routing/app_router.dart';
import 'main.dart' hide main;

/// Passenger entrypoint.
///
/// No crew session initialization, no login route, no role picker.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SarathyApp(flavor: AppFlavor.passenger));
}
