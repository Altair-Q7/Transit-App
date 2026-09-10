import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/session.dart';

/// Talks to the Sarathy Core Platform's crew-facing endpoints.
class ApiService {
  ApiService({this.baseUrl = 'http://localhost:8000/api/v1'});

  final String baseUrl;

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (CrewSession.token != null) 'Authorization': 'Bearer ${CrewSession.token}',
      };

  Future<void> login(String phone, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/crew/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': phone, 'password': password},
    );
    if (res.statusCode != 200) {
      throw Exception('Incorrect phone or password');
    }
    CrewSession.token = jsonDecode(res.body)['access_token'] as String;
  }

  Future<int> startTrip({required int busId, required int routeId}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/trips/start'),
      headers: _authHeaders,
      body: jsonEncode({'bus_id': busId, 'route_id': routeId}),
    );
    if (res.statusCode != 200) {
      throw Exception('Could not start trip (${res.statusCode})');
    }
    final tripId = jsonDecode(res.body)['id'] as int;
    CrewSession.activeTripId = tripId;
    return tripId;
  }

  Future<void> endTrip(int tripId) async {
    final res = await http.post(Uri.parse('$baseUrl/trips/end/$tripId'), headers: _authHeaders);
    if (res.statusCode != 200) {
      throw Exception('Could not end trip (${res.statusCode})');
    }
    CrewSession.activeTripId = null;
  }

  Future<void> sendGpsPing({
    required int tripId,
    required double lat,
    required double lng,
    double? speedKmh,
  }) async {
    await http.post(
      Uri.parse('$baseUrl/trips/ping'),
      headers: _authHeaders,
      body: jsonEncode({
        'trip_id': tripId,
        'latitude': lat,
        'longitude': lng,
        'speed_kmh': speedKmh,
      }),
    );
  }

  Future<void> reportIncident({required int tripId, required String type, String? note}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/trips/incident'),
      headers: _authHeaders,
      body: jsonEncode({'trip_id': tripId, 'type': type, 'note': note}),
    );
    if (res.statusCode != 200) {
      throw Exception('Could not report incident (${res.statusCode})');
    }
  }
}
