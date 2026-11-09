import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// Rule-based crash detector.
///
/// This is intentionally NOT machine learning — it's the "rule-based now,
/// upgrade to ML later" approach we agreed on. It looks for three physical
/// signs of a real fall happening together in a short window, because any
/// ONE of them alone happens during totally normal riding too:
///
///   1. IMPACT  — a sudden hard spike in acceleration (a real hit, not a
///      pothole-sized bump)
///   2. TILT    — the phone/bike rotating fast, like tipping over sideways
///   3. STOP    — your speed dropping to near-zero right after the impact
///
/// Requiring 2 of these 3 within ~2 seconds is what keeps this from
/// screaming "crash!" on every speed bump, while still catching a real fall
/// quickly. Tune the thresholds below once you've tested on your own bike —
/// every phone mount position is a little different.
class CrashDetectionService {
  // ---- Tunable thresholds — adjust after real-world testing ----
  static const double impactThresholdMs2 = 25.0; // ~2.5g, a hard hit
  static const double tiltThresholdRadS = 4.0; // fast rotation (~230°/sec)
  static const double suddenStopDropKmh = 15.0; // speed must fall by this much
  static const Duration correlationWindow = Duration(seconds: 2);
  static const Duration cooldownAfterTrigger = Duration(seconds: 30);

  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  DateTime? _lastImpactAt;
  DateTime? _lastTiltAt;
  double _lastImpactMagnitude = 0;

  // Speed samples fed in externally from the location service (sensors_plus
  // has no GPS speed of its own).
  final List<_SpeedSample> _speedSamples = [];

  DateTime? _lastTriggerAt;
  void Function(CrashEvent event)? onCrash;

  void start({required void Function(CrashEvent) onCrashDetected}) {
    onCrash = onCrashDetected;

    _accelSub = userAccelerometerEventStream().listen((e) {
      final magnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      if (magnitude >= impactThresholdMs2) {
        _lastImpactAt = DateTime.now();
        _lastImpactMagnitude = magnitude;
        _evaluate();
      }
    });

    _gyroSub = gyroscopeEventStream().listen((e) {
      final rotationMagnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      if (rotationMagnitude >= tiltThresholdRadS) {
        _lastTiltAt = DateTime.now();
        _evaluate();
      }
    });
  }

  /// Call this every time you get a new GPS speed reading (km/h).
  void updateSpeed(double speedKmh) {
    final now = DateTime.now();
    _speedSamples.add(_SpeedSample(now, speedKmh));
    _speedSamples.removeWhere((s) => now.difference(s.time) > const Duration(seconds: 5));
    _evaluate();
  }

  bool _suddenStopDetected() {
    if (_speedSamples.length < 2) return false;
    final now = DateTime.now();
    final recentEnough = _speedSamples.where((s) => now.difference(s.time) <= correlationWindow);
    if (recentEnough.isEmpty) return false;
    final maxRecentSpeed = recentEnough.map((s) => s.speedKmh).reduce(max);
    final latestSpeed = _speedSamples.last.speedKmh;
    return (maxRecentSpeed - latestSpeed) >= suddenStopDropKmh;
  }

  void _evaluate() {
    final now = DateTime.now();

    if (_lastTriggerAt != null && now.difference(_lastTriggerAt!) < cooldownAfterTrigger) {
      return; // still in cooldown from a previous trigger / active SOS flow
    }

    final impactRecent = _lastImpactAt != null && now.difference(_lastImpactAt!) <= correlationWindow;
    if (!impactRecent) return; // impact is required — it's the anchor signal

    final tiltRecent = _lastTiltAt != null && now.difference(_lastTiltAt!) <= correlationWindow;
    final stopped = _suddenStopDetected();

    // Require impact + at least one of (tilt, sudden stop).
    if (tiltRecent || stopped) {
      _lastTriggerAt = now;
      final severity = _lastImpactMagnitude > impactThresholdMs2 * 1.6 ? 'high' : 'medium';
      onCrash?.call(CrashEvent(
        triggeredAt: now,
        impactMagnitude: _lastImpactMagnitude,
        tiltDetected: tiltRecent,
        suddenStopDetected: stopped,
        severity: severity,
      ));
    }
  }

  void stop() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _speedSamples.clear();
  }
}

class _SpeedSample {
  final DateTime time;
  final double speedKmh;
  _SpeedSample(this.time, this.speedKmh);
}

class CrashEvent {
  final DateTime triggeredAt;
  final double impactMagnitude;
  final bool tiltDetected;
  final bool suddenStopDetected;
  final String severity;

  CrashEvent({
    required this.triggeredAt,
    required this.impactMagnitude,
    required this.tiltDetected,
    required this.suddenStopDetected,
    required this.severity,
  });
}
