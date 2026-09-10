/// Trip related models.

enum TripStatus {
  scheduled,
  active,
  completed,
  cancelled;

  String get value => name;
  static TripStatus fromString(String s) => TripStatus.values.firstWhere(
        (e) => e.value == s,
        orElse: () => TripStatus.scheduled,
      );
}

enum IncidentType {
  breakdown,
  traffic,
  emergency;

  String get value => name;
  static IncidentType fromString(String s) => IncidentType.values.firstWhere(
        (e) => e.value == s,
        orElse: () => IncidentType.breakdown,
      );
}

class Trip {
  final int id;
  final int busId;
  final int routeId;
  final int? crewId;
  final TripStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;

  Trip({
    required this.id,
    required this.busId,
    required this.routeId,
    this.crewId,
    required this.status,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as int,
      busId: json['bus_id'] as int,
      routeId: json['route_id'] as int,
      crewId: json['crew_id'] as int?,
      status: TripStatus.fromString(json['status'] as String),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class TripStartRequest {
  final int busId;
  final int routeId;

  TripStartRequest({required this.busId, required this.routeId});

  Map<String, dynamic> toJson() {
    return {
      'bus_id': busId,
      'route_id': routeId,
    };
  }
}

class GpsPing {
  final int tripId;
  final double latitude;
  final double longitude;
  final double? speedKmh;

  GpsPing({
    required this.tripId,
    required this.latitude,
    required this.longitude,
    this.speedKmh,
  });

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'latitude': latitude,
      'longitude': longitude,
      'speed_kmh': speedKmh,
    };
  }
}

class Incident {
  final int id;
  final int tripId;
  final IncidentType type;
  final String? note;
  final DateTime reportedAt;
  final bool adminVerified;
  final DateTime? verifiedAt;

  Incident({
    required this.id,
    required this.tripId,
    required this.type,
    this.note,
    required this.reportedAt,
    required this.adminVerified,
    this.verifiedAt,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] as int,
      tripId: json['trip_id'] as int,
      type: IncidentType.fromString(json['type'] as String),
      note: json['note'] as String?,
      reportedAt: DateTime.parse(json['reported_at'] as String),
      adminVerified: json['admin_verified'] as bool? ?? false,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
    );
  }
}

class IncidentReportRequest {
  final int tripId;
  final IncidentType type;
  final String? note;

  IncidentReportRequest({
    required this.tripId,
    required this.type,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'type': type.value,
      'note': note,
    };
  }
}