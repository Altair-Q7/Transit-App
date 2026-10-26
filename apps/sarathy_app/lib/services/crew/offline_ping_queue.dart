library;

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A single GPS ping waiting to be sent to the server.
class QueuedPing {
  final int tripId;
  final double latitude;
  final double longitude;
  final double? speedKmh;
  final DateTime queuedAt;

  const QueuedPing({
    required this.tripId,
    required this.latitude,
    required this.longitude,
    this.speedKmh,
    required this.queuedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'latitude': latitude,
      'longitude': longitude,
      if (speedKmh != null) 'speedKmh': speedKmh,
      'queuedAt': queuedAt.toIso8601String(),
    };
  }

  factory QueuedPing.fromJson(Map<String, dynamic> json) {
    return QueuedPing(
      tripId: (json['tripId'] as num).toInt(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speedKmh: json['speedKmh'] is num ? (json['speedKmh'] as num).toDouble() : null,
      queuedAt: DateTime.parse(json['queuedAt'] as String),
    );
  }
}

/// Persistent FIFO queue of GPS pings that could not be sent while offline.
///
/// Pings survive an app restart via the injectable storage adapter, which
/// defaults to [FlutterSecureStorage] under the key
/// `crew_offline_ping_queue`. The adapter is injectable so tests never touch
/// the plugin.
class OfflinePingQueue {
  static const String _storageKey = 'crew_offline_ping_queue';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  final Future<String?> Function() _read;
  final Future<void> Function(String value) _write;
  final Future<void> Function() _delete;
  final DateTime Function() _clock;

  final int maxItems;
  final Duration maxAge;
  final List<QueuedPing> _items = [];

  OfflinePingQueue({
    Future<String?> Function()? read,
    Future<void> Function(String value)? write,
    Future<void> Function()? delete,
    DateTime Function()? clock,
    this.maxItems = 200,
    this.maxAge = const Duration(hours: 2),
  })  : assert(maxItems > 0),
        assert(maxAge.inSeconds > 0),
        _read = read ?? _readFromStorage,
        _write = write ?? _writeToStorage,
        _delete = delete ?? _deleteFromStorage,
        _clock = clock ?? DateTime.now;

  static Future<String?> _readFromStorage() async {
    return await _secureStorage.read(key: _storageKey);
  }

  static Future<void> _writeToStorage(String value) async {
    await _secureStorage.write(key: _storageKey, value: value);
  }

  static Future<void> _deleteFromStorage() async {
    await _secureStorage.delete(key: _storageKey);
  }

  /// Load queued pings from storage. Corrupt or missing storage starts empty
  /// and entries older than [maxAge] are pruned. Never throws.
  Future<void> load() async {
    _items.clear();
    String? raw;
    try {
      raw = await _read();
    } catch (_) {
      raw = null;
    }
    if (raw == null || raw.isEmpty) return;

    List<dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      decoded = [];
    }

    final cutoff = _clock().subtract(maxAge);
    final originalLength = decoded.length;
    for (final entry in decoded) {
      try {
        final ping = QueuedPing.fromJson(entry as Map<String, dynamic>);
        if (!ping.queuedAt.isBefore(cutoff)) {
          _items.add(ping);
        }
      } catch (_) {
        // Skip individually corrupt entries, keep the rest.
      }
    }
    if (_items.length < originalLength) {
      await _persist();
    }
  }

  /// Add [ping] to the back of the queue. Stale entries are pruned first, and
  /// when the queue exceeds [maxItems] the oldest entries are dropped so the
  /// newest survive. Persists after every mutation.
  Future<void> add(QueuedPing ping) async {
    _pruneStale();
    _items.add(ping);
    if (_items.length > maxItems) {
      _items.removeRange(0, _items.length - maxItems);
    }
    await _persist();
  }

  /// Send queued pings in FIFO order. An item is removed only after its send
  /// succeeds, and storage is persisted immediately after each removal. On the
  /// first failure the failed item and everything after it stay queued.
  /// Returns the number of pings sent.
  Future<int> flush(Future<void> Function(QueuedPing ping) send) async {
    final before = _items.length;
    _pruneStale();
    int sent = 0;
    while (_items.isNotEmpty) {
      final ping = _items.first;
      try {
        await send(ping);
      } catch (_) {
        // First failure: stop and keep this item and everything after it.
        break;
      }
      _items.removeAt(0);
      sent++;
      await _persist();
    }
    if (sent == 0 && _items.length < before) {
      await _persist();
    }
    return sent;
  }

  /// Remove pending pings for a trip that has ended and persist.
  Future<void> clearForTrip(int tripId) async {
    _pruneStale();
    _items.removeWhere((ping) => ping.tripId == tripId);
    await _persist();
  }

  /// Clear the queue and storage (e.g. on logout).
  Future<void> clear() async {
    _items.clear();
    await _delete();
  }

  /// Number of pings pending in the queue.
  int get length => _items.length;

  /// Unmodifiable snapshot of the pending pings, oldest first.
  List<QueuedPing> get pending => List.unmodifiable(_items);

  void _pruneStale() {
    final cutoff = _clock().subtract(maxAge);
    _items.removeWhere((ping) => ping.queuedAt.isBefore(cutoff));
  }

  Future<void> _persist() async {
    await _write(jsonEncode(_items.map((ping) => ping.toJson()).toList()));
  }
}
