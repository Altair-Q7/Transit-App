/// Holds the crew member's JWT + active trip state in memory for the
/// scaffold. Swap for secure storage (flutter_secure_storage) in production.
class CrewSession {
  static String? token;
  static int? activeTripId;
}
