/// Centralized constants for the Sarathy app.
class AppConstants {
  /// Base URL for the Sarathy Core Platform API.
  /// Change this for different environments (dev, staging, prod).
  static const String defaultApiBaseUrl = 'http://localhost:8000/api/v1';

  /// Base WebSocket URL for real-time updates.
  static const String defaultWsBaseUrl = 'ws://localhost:8000';

  /// Default GPS ping interval (seconds) matching crew app cadence.
  static const int gpsPingIntervalSeconds = 5;

  /// App name for display.
  static const String appName = 'Sarathy';

  /// Tagline for display.
  static const String tagline = 'Your Journey, Guided.';

  /// Seed color for Material 3 theme.
  static const int seedColorValue = 0xFFC97B4A;
  static const int primaryColorValue = 0xFF1B2A38;
  static const int secondaryColorValue = 0xFFC97B4A;
  static const int scaffoldBackgroundValue = 0xFFF6F4EE;
  static const int appBarBackgroundValue = 0xFF1B2A38;

  /// Storage keys for secure storage.
  static const String storageKeyOperatorToken = 'operator_token';
  static const String storageKeyCrewToken = 'crew_token';
  static const String storageKeyUserRole = 'user_role';

  /// User roles.
  static const String rolePassenger = 'passenger';
  static const String roleCrew = 'crew';
  static const String roleOperator = 'operator';
}