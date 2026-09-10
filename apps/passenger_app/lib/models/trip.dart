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
}

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
}
