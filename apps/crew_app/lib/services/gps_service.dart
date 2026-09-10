import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Wraps device GPS at the ~5s cadence shown in the Crew Command mockup
/// ("Ping: 5s"). Also backs the Offline Queuing edge case: if a ping
/// fails to send (see api_service), the caller is expected to hold it
/// in a local queue and flush on reconnect — the queue itself lives in
/// TripControlScreen to keep this service focused on location only.
class GpsService {
  StreamSubscription<Position>? _sub;

  Future<bool> ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Stream<Position> watchPosition() {
    const settings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  void dispose() {
    _sub?.cancel();
  }
}
