import 'dart:async';
import 'dart:developer' as developer;

import 'package:geolocator/geolocator.dart';

class LocationService {
  static const String _tag = 'EcoLifeLocation';

  StreamSubscription<Position>? _subscription;
  final _controller = StreamController<Position>.broadcast();

  Stream<Position> get positionStream => _controller.stream;
  bool get isTracking => _subscription != null;

  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final granted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    developer.log('requestPermission: $permission (granted=$granted)', name: _tag);
    return granted;
  }

  Future<void> start() async {
    if (_subscription != null) return;
    final granted = await requestPermission();
    if (!granted) {
      developer.log('start: permission not granted, aborting.', name: _tag);
      return;
    }
    developer.log('start: beginning location updates (5s / 5m).', name: _tag);
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
    _subscription = Geolocator.getPositionStream(locationSettings: settings)
        .listen((position) {
      developer.log(
        'onPosition: lat=${position.latitude.toStringAsFixed(4)} '
        'lon=${position.longitude.toStringAsFixed(4)} '
        'alt=${position.altitude.toStringAsFixed(2)}',
        name: _tag,
      );
      _controller.add(position);
    });
  }

  void stop() {
    developer.log('stop: stopping location updates.', name: _tag);
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
