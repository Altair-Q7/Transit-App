import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Material 3 theme for Sarathy app.
class AppTheme {
  static final ColorScheme _colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(AppConstants.seedColorValue),
    primary: const Color(AppConstants.primaryColorValue),
    secondary: const Color(AppConstants.secondaryColorValue),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _colorScheme,
      scaffoldBackgroundColor: const Color(AppConstants.scaffoldBackgroundValue),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(AppConstants.appBarBackgroundValue),
        foregroundColor: Colors.white,
      ),
    );
  }
}
