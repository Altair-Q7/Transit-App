import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sarathy_app/services/crew/offline_ping_queue.dart';

const _storageKey = 'crew_offline_ping_queue';
final _now = DateTime(2026, 10, 26, 12, 0, 0);

QueuedPing makePing({
  required int tripId,
  double latitude = 10.0,
  double longitude = 76.0,
  double? speedKmh,
  required DateTime queuedAt,
}) =>
    QueuedPing(
      tripId: tripId,
      latitude: latitude,
      longitude: longitude,
      speedKmh: speedKmh,
      queuedAt: queuedAt,
    );

List<int> tripIds(List<QueuedPing> pings) => pings.map((p) => p.tripId).toList();

List<dynamic> persistedList(String? raw) =>
    jsonDecode(raw!) as List<dynamic>;

class Harness {
  Harness({
    required this.storage,
    required this.read,
    required this.write,
    required this.delete,
    DateTime Function()? clock,
  }) : queue = OfflinePingQueue(
          read: read,
          write: write,
          delete: delete,
          clock: clock,
        );

  final Map<String, String> storage;
  final Future<String?> Function() read;
  final Future<void> Function(String value) write;
  final Future<void> Function() delete;
  final OfflinePingQueue queue;
}

Harness newHarness({Map<String, String>? storage, DateTime Function()? clock}) {
  final store = storage ?? <String, String>{};
  return Harness(
    storage: store,
    read: () => Future.value(store[_storageKey]),
    write: (value) async {
      store[_storageKey] = value;
    },
    delete: () async {
      store.remove(_storageKey);
    },
    clock: clock,
  );
}

void main() {
  group('OfflinePingQueue', () {
    test('queued pings survive a new instance and load in FIFO order', () async {
      final h1 = newHarness(clock: () => _now);
      await h1.queue.add(
        makePing(tripId: 1, queuedAt: _now.subtract(const Duration(minutes: 10))),
      );
      await h1.queue.add(
        makePing(
          tripId: 2,
          speedKmh: null,
          queuedAt: _now.subtract(const Duration(minutes: 9)),
        ),
      );
      await h1.queue.add(
        makePing(tripId: 3, queuedAt: _now.subtract(const Duration(minutes: 8))),
      );

      final h2 = newHarness(storage: h1.storage, clock: () => _now);
      await h2.queue.load();

      expect(h2.queue.length, 3);
      expect(tripIds(h2.queue.pending), [1, 2, 3]);
      expect(h2.queue.pending.elementAt(1).speedKmh, isNull);
      expect(
        h2.queue.pending.elementAt(2).queuedAt,
        _now.subtract(const Duration(minutes: 8)),
      );

      final persisted = persistedList(h1.storage[_storageKey]);
      expect(persisted, hasLength(3));
    });

    test('flush sends all in order and leaves the queue empty', () async {
      final h = newHarness(clock: () => _now);
      await h.queue.add(
        makePing(tripId: 1, queuedAt: _now.subtract(const Duration(minutes: 10))),
      );
      await h.queue.add(
        makePing(tripId: 2, queuedAt: _now.subtract(const Duration(minutes: 9))),
      );
      await h.queue.add(
        makePing(tripId: 3, queuedAt: _now.subtract(const Duration(minutes: 8))),
      );

      final sent = <QueuedPing>[];
      final count = await h.queue.flush((ping) async {
        sent.add(ping);
      });

      expect(count, 3);
      expect(tripIds(sent), [1, 2, 3]);
      expect(h.queue.length, 0);
      expect(h.queue.pending, isEmpty);
      expect(persistedList(h.storage[_storageKey]), isEmpty);
    });

    test('when send throws on the second item, the first is removed and the rest remain',
        () async {
      final h = newHarness(clock: () => _now);
      await h.queue.add(
        makePing(tripId: 1, queuedAt: _now.subtract(const Duration(minutes: 10))),
      );
      await h.queue.add(
        makePing(tripId: 2, queuedAt: _now.subtract(const Duration(minutes: 9))),
      );
      await h.queue.add(
        makePing(tripId: 3, queuedAt: _now.subtract(const Duration(minutes: 8))),
      );

      int attempts = 0;
      final count = await h.queue.flush((ping) async {
        attempts++;
        if (attempts == 2) {
          throw Exception('connection lost');
        }
      });

      expect(count, 1);
      expect(tripIds(h.queue.pending), [2, 3]);

      // A fresh instance backed by the same storage sees the same items.
      final h2 = newHarness(storage: h.storage, clock: () => _now);
      await h2.queue.load();
      expect(h2.queue.length, 2);
      expect(tripIds(h2.queue.pending), [2, 3]);

      final persisted =
          persistedList(h.storage[_storageKey])
              .cast<Map<String, dynamic>>()
              .map(QueuedPing.fromJson)
              .toList();
      expect(tripIds(persisted), [2, 3]);
    });

    test('maxItems drops the oldest and keeps the newest', () async {
      final h = newHarness(clock: () => _now);
      final small = OfflinePingQueue(
        read: h.read,
        write: h.write,
        delete: h.delete,
        clock: () => _now,
        maxItems: 2,
      );
      await small.add(
        makePing(tripId: 1, queuedAt: _now.subtract(const Duration(minutes: 10))),
      );
      await small.add(
        makePing(tripId: 2, queuedAt: _now.subtract(const Duration(minutes: 9))),
      );
      await small.add(
        makePing(tripId: 3, queuedAt: _now.subtract(const Duration(minutes: 8))),
      );

      expect(small.length, 2);
      expect(tripIds(small.pending), [2, 3]);

      final persisted =
          persistedList(h.storage[_storageKey])
              .cast<Map<String, dynamic>>()
              .map(QueuedPing.fromJson)
              .toList();
      expect(tripIds(persisted), [2, 3]);
    });

    test('entries older than maxAge are pruned on load (fixed clock)', () async {
      final h = newHarness(clock: () => _now);
      h.storage[_storageKey] = jsonEncode([
        makePing(
          tripId: 1,
          queuedAt: _now.subtract(const Duration(hours: 3)),
        ).toJson(),
        makePing(
          tripId: 2,
          queuedAt: _now.subtract(const Duration(hours: 1)),
        ).toJson(),
      ]);

      await h.queue.load();

      expect(h.queue.length, 1);
      expect(tripIds(h.queue.pending), [2]);
    });

    test('load never throws on corrupt storage', () async {
      final h = newHarness(clock: () => _now);
      h.storage[_storageKey] = 'not-json-at-all';

      await h.queue.load();

      expect(h.queue.length, 0);
      expect(h.queue.pending, isEmpty);
    });
  });
}
