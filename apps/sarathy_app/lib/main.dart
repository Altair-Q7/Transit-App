import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'services/auth/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize auth state
  await AuthService.initializeCrewSession();

  runApp(const SarathyApp(flavor: AppFlavor.dev));
}

class SarathyApp extends StatefulWidget {
  final AppFlavor flavor;

  const SarathyApp({super.key, this.flavor = AppFlavor.dev});

  @override
  State<SarathyApp> createState() => _SarathyAppState();
}

class _SarathyAppState extends State<SarathyApp> {
  late final GoRouter _router = AppRouter.create(widget.flavor);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sarathy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
