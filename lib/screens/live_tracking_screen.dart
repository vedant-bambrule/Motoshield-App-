import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../services/location_service.dart';
import '../services/crash_detection_service.dart';
import '../services/firestore_service.dart';
import 'sos_screen.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});
  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final _location = LocationService();
  final _crashDetector = CrashDetectionService();
  final _firestore = FirestoreService();
  final _mapController = MapController();

  StreamSubscription<Position>? _posSub;
  String? _rideId;
  final List<LatLng> _route = [];
  Position? _lastPosition;

  bool _rideActive = false;
  bool _permissionOk = false;
  bool _tileLoadFailed = false;
  double _speedKmh = 0;
  double _maxSpeed = 0;
  double _distanceKm = 0;
  int _seconds = 0;
  Timer? _clock;
  final List<String> _flags = [];

  @override
  void dispose() {
    _posSub?.cancel();
    _crashDetector.stop();
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _startRide() async {
    _permissionOk = await _location.ensurePermission();
    if (!_permissionOk) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required to start a ride.')),
        );
      }
      return;
    }

    final doc = await _firestore.startRide();
    _rideId = doc.id;

    setState(() { _rideActive = true; _route.clear(); _distanceKm = 0; _seconds = 0; _maxSpeed = 0; _flags.clear(); _tileLoadFailed = false; });

    _clock = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _seconds++));

    _posSub = _location.positionStream().listen((pos) {
      final speed = _location.speedKmh(pos);
      _crashDetector.updateSpeed(speed);

      if (_lastPosition != null) {
        final meters = _location.distanceMeters(_lastPosition!, pos);
        if (meters > 1) _distanceKm += meters / 1000;
        if (speed > 60 && _lastPosition!.speed * 3.6 < 40) {
          if (!_flags.contains('Rapid acceleration')) _flags.add('Rapid acceleration');
        }
      }
      _lastPosition = pos;

      final point = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _speedKmh = speed;
        _maxSpeed = speed > _maxSpeed ? speed : _maxSpeed;
        _route.add(point);
      });

      // THE FIX: actually move the camera to follow the rider.
      try {
        _mapController.move(point, _mapController.camera.zoom);
      } catch (_) {
        // Map not attached yet on the very first tick — safe to ignore.
      }

      _firestore.updateRideTelemetry(_rideId!, distanceKm: _distanceKm, durationSec: _seconds, avgSpeed: _speedKmh, maxSpeed: _maxSpeed);
    });

    _crashDetector.start(onCrashDetected: (event) {
      _posSub?.pause();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SosScreen(autoTriggered: true, rideId: _rideId, impactMagnitude: event.impactMagnitude),
      )).then((_) => _posSub?.resume());
    });
  }

  Future<void> _endRide() async {
    _posSub?.cancel();
    _crashDetector.stop();
    _clock?.cancel();

    int score = 100;
    if (_flags.contains('Rapid acceleration')) score -= 12;
    if (_maxSpeed > 80) score -= 15;

    if (_rideId != null) {
      await _firestore.endRide(_rideId!, safetyScore: score.clamp(0, 100), flags: _flags);
    }
    setState(() => _rideActive = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_rideActive) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monitor_heart_outlined, color: AppColors.orange, size: 44),
              const SizedBox(height: 16),
              const Text('Ready when you are', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
              const SizedBox(height: 8),
              const Text('This uses your real GPS, accelerometer and gyroscope — crash detection runs the whole ride.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textDim)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: _startRide,
                  child: const Text('Start ride', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final mm = (_seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (_seconds % 60).toString().padLeft(2, '0');
    final center = _route.isNotEmpty ? _route.last : const LatLng(19.8762, 75.3433); // Aurangabad fallback

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(initialCenter: center, initialZoom: 15),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.motoshield.app',
                    errorTileCallback: (tile, error, stackTrace) {
                      if (!_tileLoadFailed) setState(() => _tileLoadFailed = true);
                    },
                  ),
                  if (_route.length > 1) PolylineLayer(polylines: [Polyline(points: _route, color: AppColors.orange, strokeWidth: 4)]),
                  if (_route.isNotEmpty)
                    MarkerLayer(markers: [
                      Marker(point: _route.last, width: 20, height: 20, child: const CircleAvatar(backgroundColor: AppColors.orange)),
                    ]),
                ],
              ),
              if (_tileLoadFailed)
                Positioned(
                  left: 8, right: 8, bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(10)),
                    child: const Text('Map tiles failed to load — check internet connection', style: TextStyle(color: Colors.white, fontSize: 11.5), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(children: [
                Expanded(child: AppCard(child: Column(children: [
                  Text(_speedKmh.toStringAsFixed(0), style: const TextStyle(fontFamily: 'monospace', fontSize: 34, fontWeight: FontWeight.w600, color: AppColors.text)),
                  const Eyebrow('km/h · live speed'),
                ]))),
                const SizedBox(width: 12),
                Expanded(child: AppCard(child: Column(children: [
                  Text('$mm:$ss', style: const TextStyle(fontFamily: 'monospace', fontSize: 34, fontWeight: FontWeight.w600, color: AppColors.text)),
                  const Eyebrow('duration'),
                ]))),
              ]),
              const SizedBox(height: 12),
              AppCard(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${_distanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontFamily: 'monospace', color: AppColors.text)),
                Text('max ${_maxSpeed.toStringAsFixed(0)} km/h', style: const TextStyle(fontFamily: 'monospace', color: AppColors.textDim)),
              ])),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: SizedBox(height: 50, child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SosScreen(rideId: _rideId))),
                  child: const Text('SOS', style: TextStyle(fontWeight: FontWeight.w700)),
                ))),
                const SizedBox(width: 12),
                Expanded(child: SizedBox(height: 50, child: OutlinedButton(
                  style: OutlinedButton.styleFrom(backgroundColor: AppColors.surface2, side: const BorderSide(color: AppColors.lineStrong), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: _endRide,
                  child: const Text('End ride', style: TextStyle(color: AppColors.text)),
                ))),
              ]),
              const SizedBox(height: 10),
              const Text('Crash detection is live — sudden impact + tilt or a sudden stop will open the SOS screen automatically.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: AppColors.textFaint)),
            ],
          ),
        ),
      ],
    );
  }
}