/// Shared data models for the Sarathy app.
/// Mirrors the backend's EtaResponse schema.
class EtaEstimate {
  final int tripId;
  final int stopId;
  final double etaMinutes;
  final String confidence; // low | medium | high
  final double distanceKm;
  final String status; // on_time | delayed

  EtaEstimate({
    required this.tripId,
    required this.stopId,
    required this.etaMinutes,
    required this.confidence,
    required this.distanceKm,
    required this.status,
  });

  factory EtaEstimate.fromJson(Map<String, dynamic> json) {
    return EtaEstimate(
      tripId: json['trip_id'] as int,
      stopId: json['stop_id'] as int,
      etaMinutes: (json['eta_minutes'] as num).toDouble(),
      confidence: json['confidence'] as String,
      distanceKm: (json['distance_km'] as num).toDouble(),
      status: json['status'] as String? ?? 'on_time',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'stop_id': stopId,
      'eta_minutes': etaMinutes,
      'confidence': confidence,
      'distance_km': distanceKm,
      'status': status,
    };
  }
}

/// Represents a live GPS position from a trip.
class LivePosition {
  final double lat;
  final double lng;
  final double speedKmh;

  LivePosition({required this.lat, required this.lng, required this.speedKmh});

  factory LivePosition.fromJson(Map<String, dynamic> json) {
    return LivePosition(
      lat: double.parse(json['lat'].toString()),
      lng: double.parse(json['lng'].toString()),
      speedKmh: double.tryParse(json['speed_kmh'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'speed_kmh': speedKmh,
    };
  }
}

/// Represents a bus stop.
class Stop {
  final int id;
  final int routeId;
  final String name;
  final int sequence;
  final double latitude;
  final double longitude;

  Stop({
    required this.id,
    required this.routeId,
    required this.name,
    required this.sequence,
    required this.latitude,
    required this.longitude,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'] as int,
      routeId: json['route_id'] as int,
      name: json['name'] as String,
      sequence: json['sequence'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

/// Represents a route.
class Route {
  final int id;
  final int operatorId;
  final String name;
  final String origin;
  final String destination;
  final List<Stop> stops;

  Route({
    required this.id,
    required this.operatorId,
    required this.name,
    required this.origin,
    required this.destination,
    required this.stops,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json['id'] as int,
      operatorId: json['operator_id'] as int,
      name: json['name'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      stops: (json['stops'] as List<dynamic>?)
              ?.map((e) => Stop.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Represents a bus.
class Bus {
  final int id;
  final int operatorId;
  final String registrationNumber;
  final int capacity;
  final bool active;

  Bus({
    required this.id,
    required this.operatorId,
    required this.registrationNumber,
    required this.capacity,
    required this.active,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'] as int,
      operatorId: json['operator_id'] as int,
      registrationNumber: json['registration_number'] as String,
      capacity: json['capacity'] as int? ?? 45,
      active: json['active'] as bool? ?? true,
    );
  }
}