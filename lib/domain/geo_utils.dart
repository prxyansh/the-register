import 'dart:math';

/// Haversine formula to compute distance (in meters) between two GPS points.
/// Used for venue overlap detection per SPEC.md §8.
double haversineDistance(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadiusMeters = 6371000.0;
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusMeters * c;
}

double _toRadians(double degrees) => degrees * pi / 180;
