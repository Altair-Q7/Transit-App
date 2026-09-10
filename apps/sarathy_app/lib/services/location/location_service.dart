import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Location service for GPS handling.
/// Wraps device GPS at the ~5s cadence shown in the Crew Command mockup.
/// Also backs the Offline Queuing edge case: if a ping fails to send,
/// the caller is expected to hold it in a local queue and flush on reconnect.
class LocationService {
  StreamSubscription<Position>? _positionSubscription;

  /// Ensure location permissions are granted.
  Future<bool> ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Get current position once.
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await ensurePermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Watch position stream with ~5s cadence / 5m distance filter.
  Stream<Position> watchPosition() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// Start listening to position updates with a callback.
  /// Returns a subscription that should be cancelled when done.
  StreamSubscription<Position> listenToPosition(Function(Position) onPosition) {
    _positionSubscription = watchPosition().listen(onPosition);
    return _positionSubscription!;
  }

  /// Stop listening to position updates.
  void dispose() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}