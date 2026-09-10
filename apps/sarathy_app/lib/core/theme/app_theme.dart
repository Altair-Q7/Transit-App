import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Material 3 theme for Sarathy app.
class AppTheme {
  static final ColorScheme _colorScheme = ColorScheme.fromSeed(
    seedColor: Color(AppConstants.seedColorValue),
    primary: Color(AppConstants.primaryColorValue),
    secondary: Color(AppConstants.secondaryColorValue),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _colorScheme,
      scaffoldBackgroundColor: Color(AppConstants.scaffoldBackgroundValue),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(AppConstants.appBarBackgroundValue),
        foregroundColor: Colors.white,
      ),
    );
  }
}