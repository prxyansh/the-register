import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/services/attendance_checker.dart';
import 'package:attendance_tracker/domain/detection_config.dart';

/// Tests for multi-signal scoring (Task 5) and CheckSample serialization.
void main() {
  // --- CheckSample serialization ---

  test('CheckSample serializes all signal fields to JSON', () {
    final sample = CheckSample(
      timestamp: DateTime(2026, 9, 22, 10, 0, 0),
      latitude: 10.762,
      longitude: 79.498,
      distanceMeters: 15.5,
      venueRadiusMeters: 30.0,
      insideRadius: true,
      gpsScore: 1.0,
      wifiScore: 1.0,
      motionScore: 1.0,
      sampleScore: 1.0,
      connectedSsid: 'NITT_WiFi',
      isStationary: true,
    );

    final json = sample.toJson();
    expect(json['gps_score'], 1.0);
    expect(json['wifi_score'], 1.0);
    expect(json['motion_score'], 1.0);
    expect(json['sample_score'], 1.0);
    expect(json['connected_ssid'], 'NITT_WiFi');
    expect(json['is_stationary'], true);
  });

  test('CheckSample roundtrips multi-signal fields through JSON', () {
    final original = CheckSample(
      timestamp: DateTime(2026, 9, 22, 10, 30, 0),
      latitude: 10.764,
      longitude: 79.500,
      distanceMeters: 45.2,
      venueRadiusMeters: 30.0,
      insideRadius: false,
      gpsScore: 0.0,
      wifiScore: 0.3,
      motionScore: 0.0,
      sampleScore: 0.06,
      connectedSsid: 'Other_WiFi',
      isStationary: false,
    );

    final json = original.toJson();
    final restored = CheckSample.fromJson(json);

    expect(restored.gpsScore, original.gpsScore);
    expect(restored.wifiScore, original.wifiScore);
    expect(restored.motionScore, original.motionScore);
    expect(restored.sampleScore, original.sampleScore);
    expect(restored.connectedSsid, original.connectedSsid);
    expect(restored.isStationary, original.isStationary);
  });

  test('Legacy CheckSample without signal fields parses with defaults', () {
    // Simulate a record from Task 4 (no signal fields)
    final legacyJson = {
      'timestamp': '2026-09-20T10:00:00.000',
      'lat': 10.762,
      'lng': 79.498,
      'distance_m': 12.0,
      'venue_radius_m': 30.0,
      'inside': true,
    };

    final sample = CheckSample.fromJson(legacyJson);
    expect(sample.gpsScore, 0.0); // default
    expect(sample.wifiScore, 0.5); // default (neutral)
    expect(sample.motionScore, 1.0); // default (assume stationary)
    expect(sample.sampleScore, 0.0); // default
    expect(sample.connectedSsid, isNull);
    expect(sample.isStationary, isNull);
  });

  test('checks_json array serialization with multi-signal data', () {
    final samples = [
      CheckSample(
        timestamp: DateTime(2026, 9, 22, 9, 0, 0),
        latitude: 10.762,
        longitude: 79.498,
        distanceMeters: 12.0,
        venueRadiusMeters: 30.0,
        insideRadius: true,
        gpsScore: 1.0,
        wifiScore: 1.0,
        motionScore: 1.0,
        sampleScore: 1.0,
      ),
      CheckSample(
        timestamp: DateTime(2026, 9, 22, 10, 0, 0),
        latitude: 10.763,
        longitude: 79.499,
        distanceMeters: 50.0,
        venueRadiusMeters: 30.0,
        insideRadius: false,
        gpsScore: 0.0,
        wifiScore: 0.0,
        motionScore: 0.0,
        sampleScore: 0.0,
      ),
    ];

    final checksJson = jsonEncode(samples.map((s) => s.toJson()).toList());
    final decoded = jsonDecode(checksJson) as List<dynamic>;
    final restored = decoded
        .map((e) => CheckSample.fromJson(e as Map<String, dynamic>))
        .toList();

    expect(restored.length, 2);
    expect(restored[0].sampleScore, 1.0);
    expect(restored[1].sampleScore, 0.0);
  });

  // --- detection_config.dart scoring functions ---

  test('GPS match: inside radius → 1.0', () {
    expect(gpsMatchScore(10.0, 30.0), 1.0);
    expect(gpsMatchScore(30.0, 30.0), 1.0); // exactly at radius
  });

  test('GPS match: outside radius, within 2x → partial credit', () {
    final score = gpsMatchScore(45.0, 30.0); // 1.5x radius
    expect(score, closeTo(0.5, 0.01));
  });

  test('GPS match: beyond 2x radius → 0.0', () {
    expect(gpsMatchScore(61.0, 30.0), 0.0);
    expect(gpsMatchScore(100.0, 30.0), 0.0);
  });

  test('WiFi match: venue has no SSID → neutral 0.5', () {
    expect(
        wifiMatchScore(venueWifiSsid: null, connectedSsid: 'anything'), 0.5);
    expect(wifiMatchScore(venueWifiSsid: '', connectedSsid: 'anything'), 0.5);
  });

  test('WiFi match: SSID matches (case insensitive) → 1.0', () {
    expect(
        wifiMatchScore(
            venueWifiSsid: 'NITT_WiFi', connectedSsid: 'nitt_wifi'),
        1.0);
  });

  test('WiFi match: SSID differs → 0.0', () {
    expect(
        wifiMatchScore(
            venueWifiSsid: 'NITT_WiFi', connectedSsid: 'HomeNetwork'),
        0.0);
  });

  test('WiFi match: phone not connected → 0.3', () {
    expect(wifiMatchScore(venueWifiSsid: 'NITT_WiFi', connectedSsid: null),
        0.3);
  });

  test('Motion match: stationary → 1.0', () {
    expect(motionMatchScore(isStationary: true), 1.0);
  });

  test('Motion match: moving → 0.0', () {
    expect(motionMatchScore(isStationary: false), 0.0);
  });

  test('Sample score formula: w_gps*gps + w_wifi*wifi + w_motion*motion', () {
    final score = computeSampleScore(
      gpsScore: 1.0,
      wifiScore: 1.0,
      motionScore: 1.0,
    );
    expect(score, closeTo(1.0, 0.001)); // 0.7 + 0.2 + 0.1 = 1.0

    final partialScore = computeSampleScore(
      gpsScore: 1.0,
      wifiScore: 0.0,
      motionScore: 0.0,
    );
    expect(partialScore, closeTo(0.7, 0.001)); // GPS only
  });

  test('Class confidence: average of sample scores', () {
    final confidence = computeClassConfidence([1.0, 0.7, 0.9]);
    expect(confidence, closeTo(0.867, 0.01));
  });

  test('Class confidence: empty samples → 0.0', () {
    expect(computeClassConfidence([]), 0.0);
  });

  // --- Status thresholds (§6.4) ---

  test('Status: confidence >= 0.8 → present', () {
    expect(determineStatus(0.8), 'present');
    expect(determineStatus(1.0), 'present');
  });

  test('Status: confidence <= 0.3 → absent', () {
    expect(determineStatus(0.3), 'absent');
    expect(determineStatus(0.0), 'absent');
  });

  test('Status: confidence between 0.3–0.8 → ambiguous', () {
    expect(determineStatus(0.5), 'ambiguous');
    expect(determineStatus(0.31), 'ambiguous');
    expect(determineStatus(0.79), 'ambiguous');
  });

  // --- End-to-end scenario tests ---

  test('Scenario: student at class with matching WiFi, stationary', () {
    final gps = gpsMatchScore(10.0, 30.0); // inside → 1.0
    final wifi = wifiMatchScore(
        venueWifiSsid: 'Campus_WiFi', connectedSsid: 'Campus_WiFi'); // 1.0
    final motion = motionMatchScore(isStationary: true); // 1.0
    final sampleScore = computeSampleScore(
        gpsScore: gps, wifiScore: wifi, motionScore: motion);
    expect(sampleScore, closeTo(1.0, 0.001));
    expect(determineStatus(sampleScore), 'present');
  });

  test('Scenario: student far from class, wrong WiFi, moving', () {
    final gps = gpsMatchScore(200.0, 30.0); // way outside → 0.0
    final wifi = wifiMatchScore(
        venueWifiSsid: 'Campus_WiFi', connectedSsid: 'HomeNetwork'); // 0.0
    final motion = motionMatchScore(isStationary: false); // 0.0
    final sampleScore = computeSampleScore(
        gpsScore: gps, wifiScore: wifi, motionScore: motion);
    expect(sampleScore, closeTo(0.0, 0.001));
    expect(determineStatus(sampleScore), 'absent');
  });

  test('Scenario: ambiguous — GPS match, wrong WiFi, moving', () {
    final gps = gpsMatchScore(25.0, 30.0); // inside → 1.0
    final wifi = wifiMatchScore(
        venueWifiSsid: 'Campus_WiFi', connectedSsid: 'MobileHotspot'); // 0.0
    final motion = motionMatchScore(isStationary: false); // 0.0
    final sampleScore = computeSampleScore(
        gpsScore: gps, wifiScore: wifi, motionScore: motion);
    // 0.7*1.0 + 0.2*0.0 + 0.1*0.0 = 0.7
    expect(sampleScore, closeTo(0.7, 0.001));
    expect(determineStatus(sampleScore), 'ambiguous');
  });
}
