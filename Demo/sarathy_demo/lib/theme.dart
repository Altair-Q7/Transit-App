import 'package:flutter/material.dart';

class SarathyTheme {
  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final surface = dark ? const Color(0xff182437) : Colors.white;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Arial',
      scaffoldBackgroundColor: dark
          ? const Color(0xff0d1726)
          : const Color(0xfff5f7fb),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff3977e8),
        brightness: brightness,
        primary: const Color(0xff3977e8),
        secondary: const Color(0xffff7b45),
        surface: surface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark
            ? const Color(0xff0d1726)
            : const Color(0xfff5f7fb),
        foregroundColor: dark ? Colors.white : const Color(0xff11243e),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xff3977e8), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: dark
            ? const Color(0xff263e68)
            : const Color(0xffe8efff),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: dark ? Colors.white : const Color(0xff11243e),
          ),
        ),
      ),
    );
  }
}
