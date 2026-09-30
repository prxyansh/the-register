// Detection configuration — SPEC.md §6.3.
//
// All weights and thresholds are defined here as named constants.
// To recalibrate after real-world testing (per §6.5), change ONLY
// these values — no other code needs to change.

// --- Signal Weights (must sum to 1.0) ---

/// GPS location match weight (primary signal).
const double wGps = 0.7;

/// WiFi SSID match weight (secondary signal, optional).
const double wWifi = 0.2;

/// Accelerometer / motion state weight (tertiary signal).
const double wMotion = 0.1;

// --- Status Thresholds (§6.4) ---

/// Confidence >= this → present.
const double thresholdPresent = 0.8;

/// Confidence <= this → absent.
const double thresholdAbsent = 0.3;

// Between thresholdAbsent and thresholdPresent → ambiguous.

// --- Signal Match Values ---

/// GPS match: 1.0 if inside radius, 0.0 if outside.
/// Could be made a decay function later (closer = higher score).
double gpsMatchScore(double distanceMeters, double radiusMeters) {
  if (distanceMeters <= radiusMeters) {
    return 1.0;
  }
  // Soft falloff: if within 2x radius, give partial credit
  if (distanceMeters <= radiusMeters * 2) {
    return 1.0 - ((distanceMeters - radiusMeters) / radiusMeters);
  }
  return 0.0;
}

/// WiFi match: 1.0 if connected SSID matches venue's saved SSID.
/// 0.5 if venue has no saved SSID (neutral — don't penalize).
/// 0.0 if venue has a saved SSID but phone is on a different network.
double wifiMatchScore({
  required String? venueWifiSsid,
  required String? connectedSsid,
}) {
  if (venueWifiSsid == null || venueWifiSsid.isEmpty) {
    return 0.5; // Neutral — no WiFi configured for this venue
  }
  if (connectedSsid == null || connectedSsid.isEmpty) {
    return 0.3; // Phone not connected to any WiFi — slightly negative
  }
  return connectedSsid.toLowerCase() == venueWifiSsid.toLowerCase()
      ? 1.0
      : 0.0;
}

/// Motion match: 1.0 if stationary (likely in class),
/// 0.0 if clearly moving (in transit).
double motionMatchScore({required bool isStationary}) {
  return isStationary ? 1.0 : 0.0;
}

/// Compute a single sample's score using multi-signal fusion.
/// Per SPEC §6.3: sample_score = w_gps * gps + w_wifi * wifi + w_motion * motion
double computeSampleScore({
  required double gpsScore,
  required double wifiScore,
  required double motionScore,
}) {
  return wGps * gpsScore + wWifi * wifiScore + wMotion * motionScore;
}

/// Compute the final class confidence from all sample scores.
/// Per SPEC §6.3: weighted average of all sample scores across the class.
double computeClassConfidence(List<double> sampleScores) {
  if (sampleScores.isEmpty) return 0.0;
  final sum = sampleScores.reduce((a, b) => a + b);
  return sum / sampleScores.length;
}

/// Determine attendance status from confidence score.
/// Per SPEC §6.4.
String determineStatus(double confidence) {
  if (confidence >= thresholdPresent) return 'present';
  if (confidence <= thresholdAbsent) return 'absent';
  return 'ambiguous';
}
