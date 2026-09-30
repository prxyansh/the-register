import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/domain/geo_utils.dart';

/// Tests for the Haversine distance calculator used in venue overlap detection.
void main() {
  test('Haversine: same point returns 0', () {
    final d = haversineDistance(10.762, 79.498, 10.762, 79.498);
    expect(d, closeTo(0.0, 0.01));
  });

  test('Haversine: two points ~50m apart (within overlap threshold)', () {
    // NITT campus: two points approximately 50m apart
    final d = haversineDistance(10.76200, 79.49800, 10.76245, 79.49800);
    expect(d, greaterThan(40));
    expect(d, lessThan(60));
  });

  test('Haversine: two points ~200m apart (outside overlap threshold)', () {
    // Two buildings further apart
    final d = haversineDistance(10.762, 79.498, 10.764, 79.498);
    expect(d, greaterThan(150));
  });

  test('Haversine: known distance (London to Paris ~343km)', () {
    // London: 51.5074, -0.1278
    // Paris: 48.8566, 2.3522
    final d = haversineDistance(51.5074, -0.1278, 48.8566, 2.3522);
    // Should be approximately 343km
    expect(d / 1000, closeTo(343, 5));
  });

  test('Venue overlap detection: points within 60m should trigger warning', () {
    const overlapThreshold = 60.0;
    // Two nearby venues on campus
    final distance = haversineDistance(10.76200, 79.49800, 10.76240, 79.49810);
    expect(distance <= overlapThreshold, isTrue);
  });
}
