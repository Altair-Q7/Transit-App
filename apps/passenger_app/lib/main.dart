import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SarathyPassengerApp());
}

class SarathyPassengerApp extends StatelessWidget {
  const SarathyPassengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sarathy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC97B4A),
          primary: const Color(0xFF1B2A38),
          secondary: const Color(0xFFC97B4A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F4EE),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B2A38),
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
