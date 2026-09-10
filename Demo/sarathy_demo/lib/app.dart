import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/passenger_shell.dart';
import 'screens/tracking_screen.dart';
import 'screens/settings_screen.dart';

class SarathyApp extends StatefulWidget {
  const SarathyApp({super.key});
  @override
  State<SarathyApp> createState() => _SarathyAppState();
}

class _SarathyAppState extends State<SarathyApp> {
  ThemeMode mode = ThemeMode.light;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Sarathy',
    debugShowCheckedModeBanner: false,
    theme: SarathyTheme.build(Brightness.light),
    darkTheme: SarathyTheme.build(Brightness.dark),
    themeMode: mode,
    home: LoginScreen(
      onThemeChanged: (m) => setState(() => mode = m),
      onLogin: (context) => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              PassengerShell(onThemeChanged: (m) => setState(() => mode = m)),
        ),
      ),
    ),
    routes: {
      'tracking': (_) => const TrackingScreen(),
      'settings': (_) =>
          SettingsScreen(onThemeChanged: (m) => setState(() => mode = m)),
    },
  );
}
