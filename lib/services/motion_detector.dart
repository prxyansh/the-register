import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// Accelerometer-based motion state detector — SPEC.md §6.1 (tertiary signal).
///
/// Samples accelerometer data for a short window (1 second) and determines
/// if the device is stationary vs. in transit. Used as a weak signal to
/// discount a "present" reading if the phone is clearly moving.
class MotionDetector {
  /// Threshold for accelerometer magnitude variance to distinguish
  /// stationary (< threshold) from moving (>= threshold).
  /// Gravity is ~9.8 m/s². We compare variance of magnitude around gravity.
  static const double _movementThreshold = 0.5;

  /// Sample accelerometer for ~1 second, then determine if stationary.
  /// Returns true if stationary (low variance), false if moving.
  static Future<bool> isStationary() async {
    try {
      final samples = <double>[];
      // Collect 1 second of samples
      late StreamSubscription<AccelerometerEvent> sub;
      sub = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 100),
      ).listen((event) {
        // Compute magnitude (should be ~9.8 when still)
        final magnitude =
            sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        samples.add(magnitude);
      });

      // Wait 1 second, then analyze
      await Future.delayed(const Duration(seconds: 1));
      await sub.cancel();

      if (samples.isEmpty) {
        // No accelerometer data — assume stationary (don't penalize)
        return true;
      }

      // Compute variance of magnitude
      final mean = samples.reduce((a, b) => a + b) / samples.length;
      final variance = samples
              .map((s) => (s - mean) * (s - mean))
              .reduce((a, b) => a + b) /
          samples.length;

      return variance < _movementThreshold;
    } catch (e) {
      // Accelerometer unavailable — assume stationary (don't penalize)
      return true;
    }
  }
}
