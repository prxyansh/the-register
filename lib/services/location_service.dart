import 'package:geolocator/geolocator.dart';

/// Location service — handles permission flow per SPEC.md §9.
///
/// Permission strategy:
/// 1. Request "while in use" first (foreground location)
/// 2. Only escalate to background location after explaining why
/// 3. Use PRIORITY_BALANCED_POWER for building-level checks
class LocationService {
  /// Check if we have at least foreground location permission.
  static Future<bool> hasForegroundPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Check if we have background (always) location permission.
  static Future<bool> hasBackgroundPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always;
  }

  /// Request foreground location permission ("while in use").
  /// Returns true if granted.
  static Future<bool> requestForegroundPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      if (!await Geolocator.isLocationServiceEnabled()) {
        return false;
      }
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) return false;
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Request background location permission ("always").
  /// Must be called AFTER foreground permission is granted.
  /// On Android 10+, this opens the system settings page.
  static Future<bool> requestBackgroundPermission() async {
    final current = await Geolocator.checkPermission();
    if (current == LocationPermission.always) return true;

    // On Android, requesting 'always' after 'whileInUse' opens settings
    final result = await Geolocator.requestPermission();
    if (result == LocationPermission.always) return true;

    // If it didn't prompt or was denied, force open settings
    await Geolocator.openAppSettings();
    
    // Check one more time when they return
    final check = await Geolocator.checkPermission();
    return check == LocationPermission.always;
  }

  /// Get current position with balanced power accuracy.
  /// Per SPEC §9: Use PRIORITY_BALANCED_POWER for building-level checks.
  static Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium, // ≈ balanced power
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Calculate distance from position to a venue's center (in meters).
  static double distanceTo(
    Position position,
    double venueLat,
    double venueLng,
  ) {
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      venueLat,
      venueLng,
    );
  }
}
