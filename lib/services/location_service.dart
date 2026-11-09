import 'package:geolocator/geolocator.dart';

/// Wraps real device GPS. Handles permission requests and gives a stream
/// of positions + speed (converted to km/h) for the live tracking screen
/// and the crash detector's "sudden stop" check.
class LocationService {
  Future<bool> ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return false;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    return serviceEnabled &&
        (permission == LocationPermission.always || permission == LocationPermission.whileInUse);
  }

  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // metres between updates
      ),
    );
  }

  double speedKmh(Position p) => p.speed * 3.6; // m/s -> km/h

  double distanceMeters(Position a, Position b) =>
      Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);
}
