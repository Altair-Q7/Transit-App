/// Crew session management.
/// Holds the crew member's JWT + active trip state in memory.
/// In production, consider using flutter_secure_storage for persistence.
class CrewSession {
  static String? _token;
  static int? _activeTripId;
  static int? _crewId;
  static int? _operatorId;

  static String? get token => _token;
  static int? get activeTripId => _activeTripId;
  static int? get crewId => _crewId;
  static int? get operatorId => _operatorId;

  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  static void setSession({
    required String token,
    required int crewId,
    required int operatorId,
  }) {
    _token = token;
    _crewId = crewId;
    _operatorId = operatorId;
  }

  static void setActiveTrip(int tripId) {
    _activeTripId = tripId;
  }

  static void clearActiveTrip() {
    _activeTripId = null;
  }

  static void clear() {
    _token = null;
    _activeTripId = null;
    _crewId = null;
    _operatorId = null;
  }
}