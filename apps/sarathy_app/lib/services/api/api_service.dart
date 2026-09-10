import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../models.dart';

/// Base API service for communicating with the Sarathy Core Platform.
class ApiService {
  ApiService({String? baseUrl}) : _baseUrl = baseUrl;

  String? _baseUrl;

  Future<String> get _resolvedBaseUrl async {
    if (_baseUrl != null) return _baseUrl!;
    return await AppConfig.getApiBaseUrl();
  }

  /// Build headers for authenticated requests.
  Future<Map<String, String>> _authHeaders(String token) async {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Build headers for form-data auth requests (login).
  Map<String, String> get _formHeaders => {
        'Content-Type': 'application/x-www-form-urlencoded',
      };

  /// Generic GET request.
  Future<T> _get<T>(String path, String token, T Function(dynamic) parser) async {
    final url = await _resolvedBaseUrl;
    final headers = await _authHeaders(token);
    final response = await http.get(Uri.parse('$url$path'), headers: headers);

    if (response.statusCode != 200) {
      throw ApiException('Request failed: ${response.statusCode}', response.statusCode);
    }
    return parser(jsonDecode(response.body));
  }

  /// Generic POST request with JSON body.
  Future<T> _post<T>(String path, String token, Map<String, dynamic> body,
      T Function(dynamic) parser) async {
    final url = await _resolvedBaseUrl;
    final headers = await _authHeaders(token);
    final response = await http.post(
      Uri.parse('$url$path'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Request failed: ${response.statusCode}', response.statusCode);
    }
    return parser(jsonDecode(response.body));
  }

  /// Generic POST request with form data (for login).
  Future<T> _postForm<T>(String path, Map<String, String> body,
      T Function(dynamic) parser) async {
    final url = await _resolvedBaseUrl;
    final response = await http.post(
      Uri.parse('$url$path'),
      headers: _formHeaders,
      body: body,
    );

    if (response.statusCode != 200) {
      throw ApiException('Request failed: ${response.statusCode}', response.statusCode);
    }
    return parser(jsonDecode(response.body));
  }

  // ==================== PASSENGER ENDPOINTS ====================

  /// Get ETA estimates for a stop.
  Future<List<EtaEstimate>> getEtaForStop(int stopId) async {
    final url = await _resolvedBaseUrl;
    final response = await http.get(Uri.parse('$url/eta/$stopId'));

    if (response.statusCode != 200) {
      throw ApiException('Failed to load ETA: ${response.statusCode}', response.statusCode);
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => EtaEstimate.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get live position for a trip (passenger-facing).
  Future<LivePosition> getLivePosition(int tripId) async {
    final url = await _resolvedBaseUrl;
    final response = await http.get(Uri.parse('$url/trips/$tripId/live'));

    if (response.statusCode != 200) {
      throw ApiException('No live data for this trip', response.statusCode);
    }
    return LivePosition.fromJson(jsonDecode(response.body));
  }

  // ==================== CREW ENDPOINTS ====================

  /// Crew login with phone and password.
  Future<AuthTokens> crewLogin(CrewCredentials credentials) async {
    return _postForm<AuthTokens>(
      '/auth/crew/login',
      credentials.toFormData(),
      (json) => AuthTokens.fromJson(json, UserRole.crew),
    );
  }

  /// Start a new trip.
  Future<Trip> startTrip(TripStartRequest request, String token) async {
    return _post<Trip>(
      '/trips/start',
      token,
      request.toJson(),
      (json) => Trip.fromJson(json),
    );
  }

  /// End a trip.
  Future<Trip> endTrip(int tripId, String token) async {
    return _post<Trip>(
      '/trips/end/$tripId',
      token,
      {},
      (json) => Trip.fromJson(json),
    );
  }

  /// Send GPS ping for active trip.
  Future<void> sendGpsPing(GpsPing ping, String token) async {
    await _post(
      '/trips/ping',
      token,
      ping.toJson(),
      (json) => null,
    );
  }

  /// Report an incident.
  Future<Incident> reportIncident(IncidentReportRequest request, String token) async {
    return _post<Incident>(
      '/trips/incident',
      token,
      request.toJson(),
      (json) => Incident.fromJson(json),
    );
  }

  // ==================== OPERATOR ENDPOINTS ====================

  /// Operator login with email and password.
  Future<AuthTokens> operatorLogin(OperatorCredentials credentials) async {
    return _postForm<AuthTokens>(
      '/auth/operator/login',
      credentials.toFormData(),
      (json) => AuthTokens.fromJson(json, UserRole.operator),
    );
  }

  /// Operator signup.
  Future<AuthTokens> operatorSignup(OperatorSignupData data) async {
    final url = await _resolvedBaseUrl;
    final response = await http.post(
      Uri.parse('$url/auth/operator/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Signup failed: ${response.statusCode}', response.statusCode);
    }
    return AuthTokens.fromJson(jsonDecode(response.body), UserRole.operator);
  }

  /// List buses for the operator.
  Future<List<Bus>> listBuses(String token) async {
    return _get<List<Bus>>(
      '/buses',
      token,
      (json) => (json as List).map((e) => Bus.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// Add a new bus.
  Future<Bus> addBus(String token, String registrationNumber, int capacity) async {
    return _post<Bus>(
      '/buses',
      token,
      {'registration_number': registrationNumber, 'capacity': capacity},
      (json) => Bus.fromJson(json),
    );
  }

  /// List routes for the operator.
  Future<List<Route>> listRoutes(String token) async {
    return _get<List<Route>>(
      '/routes',
      token,
      (json) => (json as List).map((e) => Route.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// Get operator stats (KPIs).
  Future<OperatorStats> getOperatorStats(String token) async {
    return _get<OperatorStats>(
      '/admin/stats',
      token,
      (json) => OperatorStats.fromJson(json),
    );
  }

  /// Verify an incident (admin action).
  Future<Map<String, dynamic>> verifyIncident(int incidentId, String token) async {
    return _post<Map<String, dynamic>>(
      '/admin/incidents/$incidentId/verify',
      token,
      {},
      (json) => json as Map<String, dynamic>,
    );
  }
}

/// Custom exception for API errors.
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}