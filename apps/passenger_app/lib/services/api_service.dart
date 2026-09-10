import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trip.dart';

/// Talks to the Sarathy Core Platform's passenger-facing endpoints.
/// No auth needed here — ETA search is anonymous, matching the deck's
/// B2C "Input: stop searches, app attention, ad impressions" flow.
class ApiService {
  ApiService({this.baseUrl = 'http://localhost:8000/api/v1'});

  final String baseUrl;

  Future<List<EtaEstimate>> getEtaForStop(int stopId) async {
    final res = await http.get(Uri.parse('$baseUrl/eta/$stopId'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load ETA (${res.statusCode})');
    }
    final List<dynamic> data = jsonDecode(res.body);
    return data.map((e) => EtaEstimate.fromJson(e)).toList();
  }
}
