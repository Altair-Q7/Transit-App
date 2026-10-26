import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models.dart';
import '../../../services.dart';

/// Live OSM map for a single trip. The map library is free and keeps the
/// Flutter code compatible with Android and iOS.
class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key, required this.tripId, required this.stopName});

  final int tripId;
  final String stopName;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  late final WebSocketService _socket;
  LivePosition? _position;

  @override
  void initState() {
    super.initState();
    _socket = WebSocketService();
    _socket.connect(widget.tripId).listen((pos) => setState(() => _position = pos));
  }

  @override
  void dispose() {
    _socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    final mapCenter = position == null
        ? const LatLng(10.0159, 76.3419) // Kerala demo center
        : LatLng(position.lat, position.lng);

    return Scaffold(
      appBar: AppBar(title: Text('Trip #${widget.tripId} — ${widget.stopName}')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(initialCenter: mapCenter, initialZoom: 13),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sarathy.app',
                ),
                if (position != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(position.lat, position.lng),
                        width: 48,
                        height: 48,
                        child: const Icon(Icons.directions_bus, color: Colors.blue, size: 40),
                      ),
                    ],
                  ),
                const RichAttributionWidget(
                  attributions: [TextSourceAttribution('OpenStreetMap contributors')],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              position == null
                  ? 'Waiting for live GPS…'
                  : 'Bus at ${position.lat.toStringAsFixed(4)}, '
                      '${position.lng.toStringAsFixed(4)} '
                      '(${position.speedKmh.toStringAsFixed(0)} km/h)',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
