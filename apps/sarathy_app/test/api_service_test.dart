import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sarathy_app/services/api/api_service.dart';

/// A recording test client that captures every request and returns a fixed
/// response. It never adds an Authorization header of its own.
class _RecordingClient extends http.BaseClient {
  // ignore: unused_element_parameter
  _RecordingClient(this.body, {this.statusCode = 200});

  final String body;
  final int statusCode;
  final List<http.BaseRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }
}

bool _hasAuthorizationHeader(http.BaseRequest request) =>
    request.headers.keys.any((key) => key.toLowerCase() == 'authorization');

String? _authorizationHeader(http.BaseRequest request) {
  final key = request.headers.keys.firstWhere(
    (k) => k.toLowerCase() == 'authorization',
    orElse: () => '',
  );
  return key.isEmpty ? null : request.headers[key];
}

void main() {
  group('ApiService passenger endpoints are unauthenticated', () {
    test('getEtaForStop calls /eta/7 with no Authorization header', () async {
      final client = _RecordingClient(
        '[{"trip_id":1,"stop_id":7,"eta_minutes":5,"confidence":"high",'
        '"distance_km":1.2,"status":"on_time"}]',
      );
      final api = ApiService(
        baseUrl: 'http://test.local/api/v1',
        client: client,
      );

      final result = await api.getEtaForStop(7);

      expect(client.requests.length, 1);
      expect(client.requests.single.url.path, '/api/v1/eta/7');
      expect(client.requests.single.url.toString(),
          'http://test.local/api/v1/eta/7');
      expect(_hasAuthorizationHeader(client.requests.single), isFalse);
      expect(result, hasLength(1));
      expect(result.first.stopId, 7);
    });

    test('searchStops calls /stops/search?q=kochi with no Authorization header',
        () async {
      final client = _RecordingClient(
        '[{"id":1,"route_id":1,"name":"Kochi Stop","sequence":1,'
        '"latitude":10.0,"longitude":76.0}]',
      );
      final api = ApiService(
        baseUrl: 'http://test.local/api/v1',
        client: client,
      );

      final result = await api.searchStops('kochi');

      expect(client.requests.length, 1);
      expect(client.requests.single.url.path, '/api/v1/stops/search');
      expect(client.requests.single.url.query, 'q=kochi');
      expect(_hasAuthorizationHeader(client.requests.single), isFalse);
      expect(result, hasLength(1));
      expect(result.first.name, 'Kochi Stop');
    });

    test('getLivePosition calls /trips/3/live with no Authorization header',
        () async {
      final client = _RecordingClient(
        '{"lat":10.0,"lng":76.0,"speed_kmh":25.0}',
      );
      final api = ApiService(
        baseUrl: 'http://test.local/api/v1',
        client: client,
      );

      final result = await api.getLivePosition(3);

      expect(client.requests.length, 1);
      expect(client.requests.single.url.path, '/api/v1/trips/3/live');
      expect(client.requests.single.url.toString(),
          'http://test.local/api/v1/trips/3/live');
      expect(_hasAuthorizationHeader(client.requests.single), isFalse);
      expect(result.lat, 10.0);
      expect(result.lng, 76.0);
    });
  });

  test('authenticated operator calls still send Authorization: Bearer <token>',
      () async {
    final client = _RecordingClient('[]');
    final api = ApiService(
      baseUrl: 'http://test.local/api/v1',
      client: client,
    );

    final buses = await api.listBuses('tok');

    expect(client.requests.length, 1);
    expect(client.requests.single.url.path, '/api/v1/buses');
    expect(_authorizationHeader(client.requests.single), 'Bearer tok');
    expect(buses, isEmpty);
  });
}
