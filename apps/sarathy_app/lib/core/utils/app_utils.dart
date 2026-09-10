/// Utility functions for the Sarathy app.

/// Formats a duration in minutes to a human-readable string.
String formatDuration(double minutes) {
  if (minutes < 1) {
    return '< 1 min';
  }
  if (minutes < 60) {
    return '${minutes.round()} min';
  }
  final hours = (minutes / 60).floor();
  final remainingMinutes = (minutes % 60).round();
  if (remainingMinutes == 0) {
    return '$hours hr';
  }
  return '$hours hr $remainingMinutes min';
}

/// Formats a distance in kilometers to a human-readable string.
String formatDistance(double km) {
  if (km < 1) {
    return '${(km * 1000).round()} m';
  }
  return '${km.toStringAsFixed(1)} km';
}

/// Parses a confidence string to a display-friendly format.
String formatConfidence(String confidence) {
  switch (confidence.toLowerCase()) {
    case 'high':
      return 'High';
    case 'medium':
      return 'Medium';
    case 'low':
      return 'Low';
    default:
      return confidence.capitalize();
  }
}

/// Extension to capitalize the first letter of a string.
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}