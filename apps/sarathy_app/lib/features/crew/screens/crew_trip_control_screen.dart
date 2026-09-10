import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models.dart';
import '../../../services.dart';

/// Mirrors the "Crew Command" mockup: trip status + ping cadence header,
/// a big One-Tap Trip Start button, and Breakdown / Traffic / Emergency
/// quick-report tiles feeding the False-Alarm Filter Protocol.
class CrewTripControlScreen extends StatefulWidget {
  const CrewTripControlScreen({super.key});

  @override
  State<CrewTripControlScreen> createState() => _CrewTripControlScreenState();
}

class _CrewTripControlScreenState extends State<CrewTripControlScreen> {
  final _api = ApiService();
  final _gps = LocationService();
  StreamSubscription<Position>? _positionSub;

  bool _tripActive = false;
  int? _tripId;
  DateTime? _lastPing;

  // Offline Queuing edge case: pings that failed to send while offline
  // are held here and flushed opportunistically on the next successful ping.
  final List<Map<String, dynamic>> _queuedPings = [];

  @override
  void dispose() {
    _positionSub?.cancel();
    _gps.dispose();
    super.dispose();
  }

  Future<void> _startTrip() async {
    // In production, bus_id/route_id come from the Configuration step
    // (Node 2 of the flywheel) rather than being hardcoded here.
    try {
      final tripId = await _api.startTrip(
        TripStartRequest(busId: 1, routeId: 1),
        CrewSession.token!,
      );
      setState(() {
        _tripId = tripId.id;
        _tripActive = true;
      });
      CrewSession.setActiveTrip(tripId.id);
      _beginGpsStream();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _endTrip() async {
    if (_tripId == null) return;
    try {
      await _api.endTrip(_tripId!, CrewSession.token!);
      _positionSub?.cancel();
      setState(() {
        _tripActive = false;
        _tripId = null;
      });
      CrewSession.clearActiveTrip();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _beginGpsStream() {
    _positionSub = _gps.watchPosition().listen((pos) async {
      if (_tripId == null) return;
      setState(() => _lastPing = DateTime.now());

      try {
        await _api.sendGpsPing(
          GpsPing(
            tripId: _tripId!,
            latitude: pos.latitude,
            longitude: pos.longitude,
            speedKmh: pos.speed * 3.6,
          ),
          CrewSession.token!,
        );
        // Flush anything queued from a prior offline stretch.
        while (_queuedPings.isNotEmpty) {
          final queued = _queuedPings.removeAt(0);
          await _api.sendGpsPing(
            GpsPing(
              tripId: queued['tripId'],
              latitude: queued['lat'],
              longitude: queued['lng'],
              speedKmh: queued['speedKmh'],
            ),
            CrewSession.token!,
          );
        }
      } catch (_) {
        // Local Cache: queue the packet, sync when signal is restored.
        _queuedPings.add({
          'tripId': _tripId,
          'lat': pos.latitude,
          'lng': pos.longitude,
          'speedKmh': pos.speed * 3.6,
        });
      }
    });
  }

  Future<void> _reportIncident(String type) async {
    if (_tripId == null) return;
    try {
      await _api.reportIncident(
        IncidentReportRequest(
          tripId: _tripId!,
          type: IncidentType.fromString(type),
        ),
        CrewSession.token!,
      );
      _showInfo('$type reported — pending admin verification.');
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crew Command')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFC9D3D6)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Trip: ${_tripActive ? "Active" : "Idle"}'),
                  Text(_lastPing == null ? 'Ping: —' : 'Ping: 5s'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 140,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC97B4A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _tripActive ? _endTrip : _startTrip,
                child: Text(
                  _tripActive ? 'End Trip' : 'One-Tap\nTrip Start',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _IncidentTile(
                    label: 'Breakdown',
                    onTap: () => _reportIncident('breakdown'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _IncidentTile(
                    label: 'Traffic',
                    onTap: () => _reportIncident('traffic'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _IncidentTile(
                    label: 'Emergency',
                    onTap: () => _reportIncident('emergency'),
                    flagged: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  const _IncidentTile({required this.label, required this.onTap, this.flagged = false});

  final String label;
  final VoidCallback onTap;
  final bool flagged;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        side: const BorderSide(color: Color(0xFFC9D3D6)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: Text(label)),
          if (flagged)
            const Positioned(
              top: -10,
              right: -10,
              child: CircleAvatar(radius: 6, backgroundColor: Colors.red),
            ),
        ],
      ),
    );
  }
}