import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../services/websocket_service.dart';

/// Live map placeholder for a single trip. Swap the placeholder Container
/// for your map SDK of choice (Google Maps / Mapbox) and plot [position].
class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key, required this.tripId, required this.stopName});

  final int tripId;
  final String stopName;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  late final TripSocket _socket;
  LivePosition? _position;

  @override
  void initState() {
    super.initState();
    _socket = TripSocket(tripId: widget.tripId);
    _socket.connect().listen((pos) => setState(() => _position = pos));
  }

  @override
  void dispose() {
    _socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trip #${widget.tripId} — ${widget.stopName}')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFF6F4EE),
              alignment: Alignment.center,
              child: Text(
                _position == null
                    ? 'Waiting for live GPS…'
                    : 'Bus at ${_position!.lat.toStringAsFixed(4)}, '
                      '${_position!.lng.toStringAsFixed(4)} '
                      '(${_position!.speedKmh.toStringAsFixed(0)} km/h)',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
