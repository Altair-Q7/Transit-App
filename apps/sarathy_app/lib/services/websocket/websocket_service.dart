import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/config/app_config.dart';
import '../../models.dart';

/// WebSocket service for real-time trip updates.
/// Subscribes to a single trip's live GPS feed — the "WebSocket
/// (Real-Time Live Updates)" link from the architecture slide.
class WebSocketService {
  WebSocketChannel? _channel;
  int? _currentTripId;

  /// Connect to the trip WebSocket.
  /// Returns a stream of LivePosition updates.
  Stream<LivePosition> connect(int tripId) async* {
    _currentTripId = tripId;
    final wsUrl = await AppConfig.getWsBaseUrl();
    _channel = WebSocketChannel.connect(Uri.parse('$wsUrl/api/v1/ws/trip/$tripId'));

    await for (final message in _channel!.stream) {
      try {
        final data = jsonDecode(message as String);
        yield LivePosition.fromJson(data as Map<String, dynamic>);
      } catch (e) {
        // Ignore parse errors, continue listening
      }
    }
  }

  /// Disconnect from the WebSocket.
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _currentTripId = null;
  }

  /// Get the currently connected trip ID.
  int? get currentTripId => _currentTripId;

  /// Check if currently connected.
  bool get isConnected => _channel != null;
}