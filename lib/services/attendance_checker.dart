import 'dart:convert';
import 'package:drift/drift.dart';
import '../data/app_database.dart';
import '../data/attendance_status.dart';
import '../domain/detection_config.dart';
import 'location_service.dart';
import 'wifi_checker.dart';
import 'motion_detector.dart';

/// A single raw sample check — logged into checks_json.
/// Captures all three signals: GPS, WiFi, and motion.
class CheckSample {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final double venueRadiusMeters;
  final bool insideRadius;

  // Multi-signal fields (Task 5)
  final double gpsScore;
  final double wifiScore;
  final double motionScore;
  final double sampleScore;
  final String? connectedSsid;
  final bool? isStationary;

  CheckSample({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.venueRadiusMeters,
    required this.insideRadius,
    this.gpsScore = 0.0,
    this.wifiScore = 0.5,
    this.motionScore = 1.0,
    this.sampleScore = 0.0,
    this.connectedSsid,
    this.isStationary,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'lat': latitude,
        'lng': longitude,
        'distance_m': distanceMeters,
        'venue_radius_m': venueRadiusMeters,
        'inside': insideRadius,
        'gps_score': gpsScore,
        'wifi_score': wifiScore,
        'motion_score': motionScore,
        'sample_score': sampleScore,
        if (connectedSsid != null) 'connected_ssid': connectedSsid,
        if (isStationary != null) 'is_stationary': isStationary,
      };

  factory CheckSample.fromJson(Map<String, dynamic> json) => CheckSample(
        timestamp: DateTime.parse(json['timestamp'] as String),
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lng'] as num).toDouble(),
        distanceMeters: (json['distance_m'] as num).toDouble(),
        venueRadiusMeters: (json['venue_radius_m'] as num).toDouble(),
        insideRadius: json['inside'] as bool,
        gpsScore: (json['gps_score'] as num?)?.toDouble() ?? 0.0,
        wifiScore: (json['wifi_score'] as num?)?.toDouble() ?? 0.5,
        motionScore: (json['motion_score'] as num?)?.toDouble() ?? 1.0,
        sampleScore: (json['sample_score'] as num?)?.toDouble() ?? 0.0,
        connectedSsid: json['connected_ssid'] as String?,
        isStationary: json['is_stationary'] as bool?,
      );
}

/// Multi-signal attendance checker — SPEC.md §6.1-6.4.
///
/// Performs GPS + WiFi + motion checks for a specific timetable entry.
/// Uses weighted scoring from detection_config.dart.
class AttendanceChecker {
  final AppDatabase db;

  AttendanceChecker(this.db);

  /// Perform a multi-signal check for a timetable entry.
  ///
  /// Signals:
  /// 1. GPS location — primary (weight 0.7)
  /// 2. WiFi SSID — secondary (weight 0.2)
  /// 3. Accelerometer motion — tertiary (weight 0.1)
  Future<CheckSample?> performCheck(TimetableEntry entry) async {
    // Entry must have a venue
    if (entry.venueId == null) return null;

    try {
      // Get venue data
      final venue = await db.venuesDao.getVenueById(entry.venueId!);

      // --- Signal 1: GPS ---
      final position = await LocationService.getCurrentPosition();
      final distance = LocationService.distanceTo(
        position,
        venue.latitude,
        venue.longitude,
      );
      final inside = distance <= venue.radiusMeters;
      final gpsScore = gpsMatchScore(distance, venue.radiusMeters);

      // --- Signal 2: WiFi SSID ---
      final connectedSsid = await WifiChecker.getConnectedSsid();
      final wifiScore = wifiMatchScore(
        venueWifiSsid: venue.wifiSsid,
        connectedSsid: connectedSsid,
      );

      // --- Signal 3: Motion (accelerometer) ---
      final isStationary = await MotionDetector.isStationary();
      final motionScore = motionMatchScore(isStationary: isStationary);

      // --- Compute sample score (§6.3) ---
      final sScore = computeSampleScore(
        gpsScore: gpsScore,
        wifiScore: wifiScore,
        motionScore: motionScore,
      );

      // Create sample
      final sample = CheckSample(
        timestamp: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        distanceMeters: distance,
        venueRadiusMeters: venue.radiusMeters,
        insideRadius: inside,
        gpsScore: gpsScore,
        wifiScore: wifiScore,
        motionScore: motionScore,
        sampleScore: sScore,
        connectedSsid: connectedSsid,
        isStationary: isStationary,
      );

      // Find or create today's attendance record
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final existingRecords = await (db.select(db.attendanceRecords)
            ..where((r) =>
                r.timetableEntryId.equals(entry.id) &
                r.date.isBiggerOrEqualValue(startOfDay) &
                r.date.isSmallerThanValue(endOfDay)))
          .get();

      int recordId;
      List<CheckSample> allSamples;

      if (existingRecords.isEmpty) {
        recordId = await db.attendanceRecordsDao.insertRecord(
          AttendanceRecordsCompanion.insert(
            timetableEntryId: entry.id,
            date: startOfDay,
            status: AttendanceStatus.ambiguous.toDbValue(),
          ),
        );
        allSamples = [sample];
      } else {
        final record = existingRecords.first;
        recordId = record.id;

        final existingJson =
            jsonDecode(record.checksJson) as List<dynamic>;
        allSamples = existingJson
            .map((e) => CheckSample.fromJson(e as Map<String, dynamic>))
            .toList();
        allSamples.add(sample);
      }

      // --- Compute final class confidence (§6.3) ---
      final sampleScores = allSamples.map((s) => s.sampleScore).toList();
      final classConfidence = computeClassConfidence(sampleScores);

      // --- Determine status (§6.4) ---
      final status = determineStatus(classConfidence);

      // Update the record
      final checksJson =
          jsonEncode(allSamples.map((s) => s.toJson()).toList());
      await db.attendanceRecordsDao.updateDetectionResult(
        recordId,
        classConfidence,
        status,
        checksJson,
      );

      return sample;
    } catch (e) {
      // Location unavailable — log and continue silently
      return null;
    }
  }
}
