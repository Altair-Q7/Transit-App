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

String? _authorizationHeader(http.BaseRequest request) {
  final key = request.headers.keys.firstWhere(
    (k) => k.toLowerCase() == 'authorization',
    orElse: () => '',
  );
  return key.isEmpty ? null : request.headers[key];
}

void main() {
  group('ApiService crew endpoints', () {
    test('getCrewMe parses /crew/me and sends Authorization: Bearer tok', () async {
      final client = _RecordingClient(
        '{"id":42,"name":"Anees","phone":"+919999999999","role":"driver","operator_id":7}',
      );
      final api = ApiService(
        baseUrl: 'http://test.local/api/v1',
        client: client,
      );

      final profile = await api.getCrewMe('tok');

      expect(client.requests.length, 1);
      expect(client.requests.single.url.path, '/api/v1/crew/me');
      expect(_authorizationHeader(client.requests.single), 'Bearer tok');
      expect(profile.id, 42);
      expect(profile.name, 'Anees');
      expect(profile.phone, '+919999999999');
      expect(profile.role, 'driver');
      expect(profile.operatorId, 7);
    });

    test('listCrewBuses parses payload without operator_id, defaults operatorId to 0',
        () async {
      final client = _RecordingClient(
        '[{"id":101,"registration_number":"KL-07-AB-1234","capacity":40,"active":true}]',
      );
      final api = ApiService(
        baseUrl: 'http://test.local/api/v1',
        client: client,
      );

      final buses = await api.listCrewBuses('tok');

      expect(client.requests.length, 1);
      expect(client.requests.single.url.path, '/api/v1/crew/buses');
      expect(_authorizationHeader(client.requests.single), 'Bearer tok');
      expect(buses, hasLength(1));
      expect(buses.first.id, 101);
      expect(buses.first.registrationNumber, 'KL-07-AB-1234');
      expect(buses.first.operatorId, 0);
    });

    test('listCrewRoutes parses payload without operator_id including stops, defaults operatorId to 0',
        () async {
      final client = _RecordingClient(
        '[{"id":5,"name":"Kochi-Aluva","origin":"Kochi","destination":"Aluva","operator_id":null,"stops":[{"id":1,"route_id":5,"name":"Kochi","sequence":1,"latitude":10.0,"longitude":76.0}]}]',
      );
      final api = ApiService(
        baseUrl: 'http://test.local/api/v1',
        client: client,
      );

      final routes = await api.listCrewRoutes('tok');

      expect(client.requests.length, 1);
      expect(client.requests.single.url.path, '/api/v1/crew/routes');
      expect(_authorizationHeader(client.requests.single), 'Bearer tok');
      expect(routes, hasLength(1));
      expect(routes.first.id, 5);
      expect(routes.first.name, 'Kochi-Aluva');
      expect(routes.first.origin, 'Kochi');
      expect(routes.first.destination, 'Aluva');
      expect(routes.first.operatorId, 0);
      expect(routes.first.stops, hasLength(1));
      expect(routes.first.stops.first.name, 'Kochi');
    });
  });
}
