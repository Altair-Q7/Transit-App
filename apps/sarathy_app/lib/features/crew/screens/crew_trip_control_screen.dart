import 'dart:async';
import 'package:flutter/material.dart' hide Route;
import 'package:geolocator/geolocator.dart';
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

  // Offline queue: pings that failed while offline are persisted and flushed
  // in order once connectivity returns; they survive an app restart.
  final OfflinePingQueue _queue = OfflinePingQueue();

  // Crew fleet selection, loaded from /crew/buses and /crew/routes.
  bool _loading = true;
  String? _error;
  List<Bus> _buses = [];
  List<Route> _routes = [];
  Bus? _selectedBus;
  Route? _selectedRoute;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _queue.load();
    if (!mounted) return;
    await _loadFleet();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _gps.dispose();
    super.dispose();
  }

  /// Load the buses and routes visible to the crew member's operator.
  Future<void> _loadFleet() async {
    final token = CrewSession.token;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'No crew session. Please sign in again.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final buses = await _api.listCrewBuses(token);
      final routes = await _api.listCrewRoutes(token);
      if (!mounted) return;
      setState(() {
        _buses = buses;
        _routes = routes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  bool get _canStartTrip =>
      !_tripActive && _selectedBus != null && _selectedRoute != null;

  Future<void> _startTrip() async {
    // bus_id/route_id come from the crew's own operator fleet, selected above.
    if (_selectedBus == null || _selectedRoute == null) return;
    try {
      final tripId = await _api.startTrip(
        TripStartRequest(
          busId: _selectedBus!.id,
          routeId: _selectedRoute!.id,
        ),
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
      await _queue.clearForTrip(_tripId!);
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
    _positionSub = _gps.watchPosition(background: true).listen((pos) async {
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
        await _flushQueuedPings();
      } catch (_) {
        // Local Cache: queue the packet, sync when signal is restored.
        // A storage failure must not break the position stream, so ignore it.
        try {
          await _queue.add(QueuedPing(
            tripId: _tripId!,
            latitude: pos.latitude,
            longitude: pos.longitude,
            speedKmh: pos.speed * 3.6,
            queuedAt: DateTime.now(),
          ));
        } catch (_) {}
        if (!mounted) return;
        setState(() {});
      }
    });
  }

  /// Retry queued pings now that connectivity is back. A failed flush never
  /// escapes: remaining items stay queued for the next attempt.
  Future<void> _flushQueuedPings() async {
    try {
      await _queue.flush(
        (ping) => _api.sendGpsPing(
          GpsPing(
            tripId: ping.tripId,
            latitude: ping.latitude,
            longitude: ping.longitude,
            speedKmh: ping.speedKmh,
          ),
          CrewSession.token!,
        ),
      );
    } catch (_) {
      // Swallow flush failures; items remain queued.
    }
    if (!mounted) return;
    setState(() {});
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

  Widget _buildFleetPanel() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Column(
        children: [
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _loadFleet,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (_buses.isEmpty || _routes.isEmpty) {
      final message = _buses.isEmpty && _routes.isEmpty
          ? 'No buses or routes assigned to your operator. Trip Start is disabled.'
          : _buses.isEmpty
              ? 'No buses assigned to your operator. Trip Start is disabled.'
              : 'No routes assigned to your operator. Trip Start is disabled.';
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC9D3D6)),
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFF4EDEA),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Color(0xFF8A4B34)),
        ),
      );
    }

    return Column(
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey('bus_${_selectedBus?.id}'),
          decoration: const InputDecoration(labelText: 'Bus'),
          initialValue: _selectedBus?.id,
          items: _buses
              .map((bus) => DropdownMenuItem<int>(
                    value: bus.id,
                    child: Text(bus.registrationNumber),
                  ))
              .toList(),
          onChanged: (id) {
            if (id == null) return;
            setState(() {
              _selectedBus = _buses.firstWhere((b) => b.id == id);
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: ValueKey('route_${_selectedRoute?.id}'),
          decoration: const InputDecoration(labelText: 'Route'),
          initialValue: _selectedRoute?.id,
          items: _routes
              .map((route) => DropdownMenuItem<int>(
                    value: route.id,
                    child: Text(
                      '${route.name} (${route.origin} \u2192 ${route.destination})',
                    ),
                  ))
              .toList(),
          onChanged: (id) {
            if (id == null) return;
            setState(() {
              _selectedRoute = _routes.firstWhere((r) => r.id == id);
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crew Command')),
      body: SingleChildScrollView(
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
                  Text('Queued: ${_queue.length}'),
                  Text(_lastPing == null ? 'Ping: —' : 'Ping: 5s'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildFleetPanel(),
            const SizedBox(height: 24),
            SizedBox(
              height: 140,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC97B4A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _tripActive ? _endTrip : (_canStartTrip ? _startTrip : null),
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
