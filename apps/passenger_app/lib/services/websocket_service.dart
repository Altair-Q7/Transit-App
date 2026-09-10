import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/trip.dart';

/// Subscribes to a single trip's live GPS feed — the "WebSocket
/// (Real-Time Live Updates)" link from the architecture slide, consumed
/// from the passenger side.
class TripSocket {
  TripSocket({required this.tripId, this.baseWsUrl = 'ws://localhost:8000'});

  final int tripId;
  final String baseWsUrl;
  WebSocketChannel? _channel;

  Stream<LivePosition> connect() {
    _channel = WebSocketChannel.connect(Uri.parse('$baseWsUrl/api/v1/ws/trip/$tripId'));
    return _channel!.stream.map((raw) => LivePosition.fromJson(jsonDecode(raw as String)));
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
