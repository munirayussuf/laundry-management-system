import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError(
          'Turn on Location in your phone settings and try again.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw StateError(
          'Location permission is needed to use your exact location.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError(
          'Allow location access for Laundry Service in phone settings.');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 20),
    );
  }

  String describe(Position position) =>
      'GPS ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
}
