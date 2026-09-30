import 'dart:math';

// Adaptive polling schedule — SPEC.md §6.2.
//
// For a class of duration D minutes:
// - First 15% of class time: HIGH density (catches late arrivals)
// - Middle 70% of class time: LOW density (students stable mid-class)
// - Last 15% of class time: HIGH density (catches early leavers)
// - Check times are RANDOMIZED within each window (not fixed offsets)
// - Each check is a one-off WorkManager task, not continuous polling

/// Number of checks in each high-density window (start/end 15%).
const int kHighDensityChecks = 2;

/// Number of checks in the low-density middle window (70%).
const int kLowDensityChecks = 1;

/// Fraction of class duration for high-density windows.
const double kHighDensityFraction = 0.15;

/// Minimum class duration (in minutes) to apply adaptive scheduling.
/// Shorter classes fall back to start+end only.
const int kMinAdaptiveDurationMinutes = 20;

/// Generate adaptive check times for a class.
///
/// Returns a list of [DateTime] instances representing when checks should fire.
/// Times are randomized within their respective windows so the schedule
/// isn't predictable between runs.
///
/// For a 60-minute class (9:00–10:00):
/// - Start window (0–9 min):  2 randomized checks  → e.g. 9:02, 9:07
/// - Middle window (9–51 min): 1 randomized check   → e.g. 9:31
/// - End window (51–60 min):  2 randomized checks   → e.g. 9:53, 9:58
///
/// Total: 5 checks for a 60-min class (vs. 2 in Task 4).
List<DateTime> generateAdaptiveSchedule({
  required DateTime classStart,
  required DateTime classEnd,
  Random? random, // injectable for testing
}) {
  final rng = random ?? Random();
  final duration = classEnd.difference(classStart);
  final durationMinutes = duration.inMinutes;

  // For very short classes, just check at start and end
  if (durationMinutes < kMinAdaptiveDurationMinutes) {
    return [classStart, classEnd];
  }

  final durationMs = duration.inMilliseconds;

  // Window boundaries (in milliseconds from class start)
  final startWindowEnd = (durationMs * kHighDensityFraction).round();
  final endWindowStart = (durationMs * (1.0 - kHighDensityFraction)).round();

  final checks = <DateTime>[];

  // --- Start window: first 15% ---
  // Always include a check right at class start
  checks.add(classStart);
  // Add randomized checks within the start window
  for (int i = 1; i < kHighDensityChecks; i++) {
    // Random offset within [1 minute, startWindowEnd]
    final minOffset = 60000; // 1 minute in ms
    if (startWindowEnd > minOffset) {
      final offsetMs = minOffset + rng.nextInt(startWindowEnd - minOffset);
      checks.add(classStart.add(Duration(milliseconds: offsetMs)));
    }
  }

  // --- Middle window: 70% ---
  for (int i = 0; i < kLowDensityChecks; i++) {
    // Random offset within [startWindowEnd, endWindowStart]
    final range = endWindowStart - startWindowEnd;
    if (range > 0) {
      final offsetMs = startWindowEnd + rng.nextInt(range);
      checks.add(classStart.add(Duration(milliseconds: offsetMs)));
    }
  }

  // --- End window: last 15% ---
  for (int i = 0; i < kHighDensityChecks - 1; i++) {
    // Random offset within [endWindowStart, durationMs - 1 minute]
    final maxOffset = durationMs - 60000; // 1 minute before end
    final range = maxOffset - endWindowStart;
    if (range > 0) {
      final offsetMs = endWindowStart + rng.nextInt(range);
      checks.add(classStart.add(Duration(milliseconds: offsetMs)));
    }
  }
  // Always include a check right at class end
  checks.add(classEnd);

  // Sort chronologically and deduplicate any times too close together
  checks.sort();
  return _deduplicateChecks(checks);
}

/// Remove checks that are less than 30 seconds apart.
List<DateTime> _deduplicateChecks(List<DateTime> sorted) {
  if (sorted.isEmpty) return sorted;
  final result = [sorted.first];
  for (int i = 1; i < sorted.length; i++) {
    if (sorted[i].difference(result.last).inSeconds >= 30) {
      result.add(sorted[i]);
    }
  }
  return result;
}

/// Describe the schedule for debugging/logging.
String describeSchedule(
    DateTime classStart, DateTime classEnd, List<DateTime> checks) {
  final buf = StringBuffer();
  final duration = classEnd.difference(classStart);
  buf.writeln(
      'Adaptive schedule for ${duration.inMinutes}min class '
      '(${_fmt(classStart)} – ${_fmt(classEnd)}):');
  for (int i = 0; i < checks.length; i++) {
    final elapsed = checks[i].difference(classStart);
    final pct =
        (elapsed.inMilliseconds / duration.inMilliseconds * 100).round();
    String zone;
    if (pct <= 15) {
      zone = 'START';
    } else if (pct >= 85) {
      zone = 'END';
    } else {
      zone = 'MID';
    }
    buf.writeln(
        '  Check ${i + 1}: ${_fmt(checks[i])} (+${elapsed.inMinutes}min, $pct%, $zone)');
  }
  return buf.toString();
}

String _fmt(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
