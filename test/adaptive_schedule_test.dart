import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/domain/adaptive_schedule.dart';

/// Tests for the adaptive polling schedule — SPEC §6.2.
void main() {
  // --- Core schedule generation ---

  test('60-minute class produces 5 checks (2 start + 1 mid + 2 end)', () {
    final start = DateTime(2026, 9, 26, 9, 0);
    final end = DateTime(2026, 9, 26, 10, 0);

    final checks = generateAdaptiveSchedule(
      classStart: start,
      classEnd: end,
      random: Random(42), // seeded for determinism
    );

    // Should have 5 checks (2 start-window + 1 mid + 1 end-window + 1 end)
    expect(checks.length, greaterThanOrEqualTo(4));
    expect(checks.length, lessThanOrEqualTo(6));
  });

  test('First check is at class start', () {
    final start = DateTime(2026, 9, 26, 9, 0);
    final end = DateTime(2026, 9, 26, 10, 0);

    final checks = generateAdaptiveSchedule(
      classStart: start,
      classEnd: end,
      random: Random(42),
    );

    expect(checks.first, equals(start));
  });

  test('Last check is at class end', () {
    final start = DateTime(2026, 9, 26, 9, 0);
    final end = DateTime(2026, 9, 26, 10, 0);

    final checks = generateAdaptiveSchedule(
      classStart: start,
      classEnd: end,
      random: Random(42),
    );

    expect(checks.last, equals(end));
  });

  test('Checks are sorted chronologically', () {
    final start = DateTime(2026, 9, 26, 9, 0);
    final end = DateTime(2026, 9, 26, 10, 0);

    final checks = generateAdaptiveSchedule(
      classStart: start,
      classEnd: end,
      random: Random(42),
    );

    for (int i = 1; i < checks.length; i++) {
      expect(checks[i].isAfter(checks[i - 1]) ||
          checks[i].isAtSameMomentAs(checks[i - 1]), isTrue);
    }
  });

  test('All checks are within class window [start, end]', () {
    final start = DateTime(2026, 9, 26, 9, 0);
    final end = DateTime(2026, 9, 26, 10, 0);

    final checks = generateAdaptiveSchedule(
      classStart: start,
      classEnd: end,
      random: Random(42),
    );

    for (final check in checks) {
      expect(check.isAfter(start) || check.isAtSameMomentAs(start), isTrue,
          reason: 'Check at $check is before class start $start');
      expect(check.isBefore(end) || check.isAtSameMomentAs(end), isTrue,
          reason: 'Check at $check is after class end $end');
    }
  });

  // --- Density verification ---

  test('More checks in first/last 15% than middle 70%', () {
    final start = DateTime(2026, 9, 26, 9, 0);
    final end = DateTime(2026, 9, 26, 10, 0);
    final durationMs = end.difference(start).inMilliseconds;

    final checks = generateAdaptiveSchedule(
      classStart: start,
      classEnd: end,
      random: Random(42),
    );

    final startWindow = (durationMs * 0.15).round();
    final endWindowStart = (durationMs * 0.85).round();

    int startCount = 0, midCount = 0, endCount = 0;
    for (final check in checks) {
      final offsetMs = check.difference(start).inMilliseconds;
      if (offsetMs <= startWindow) {
        startCount++;
      } else if (offsetMs >= endWindowStart) {
        endCount++;
      } else {
        midCount++;
      }
    }

    // Start + end combined should outnumber mid
    expect(startCount + endCount, greaterThan(midCount),
        reason: 'Start ($startCount) + End ($endCount) should > Mid ($midCount)');
  });

  // --- Randomization ---

  test('Different seeds produce different check times', () {
    final start = DateTime(2026, 9, 26, 9, 0);
    final end = DateTime(2026, 9, 26, 10, 0);

    final checks1 = generateAdaptiveSchedule(
      classStart: start,
      classEnd: end,
      random: Random(1),
    );

    final checks2 = generateAdaptiveSchedule(
      classStart: start,
      classEnd: end,
      random: Random(99),
    );

    // Start and end are always the same, but middle checks should differ
    // At least one interior check should be different
    bool anyDifferent = false;
    final minLen = checks1.length < checks2.length
        ? checks1.length
        : checks2.length;
    for (int i = 1; i < minLen - 1; i++) {
      if (!checks1[i].isAtSameMomentAs(checks2[i])) {
        anyDifferent = true;
        break;
      }
    }
    expect(anyDifferent, isTrue,
        reason: 'Interior check times should differ between seeds');
  });

  // --- Edge cases ---

  test('Short class (15 min) falls back to start + end only', () {
    final start = DateTime(2026, 9, 26, 9, 0);
    final end = DateTime(2026, 9, 26, 9, 15);

    final checks = generateAdaptiveSchedule(
      classStart: start,
      classEnd: end,
      random: Random(42),
    );

    expect(checks.length, 2);
    expect(checks.first, equals(start));
    expect(checks.last, equals(end));
  });

  test('Minimum adaptive class (20 min) produces checks', () {
    final start = DateTime(2026, 9, 26, 9, 0);
    final end = DateTime(2026, 9, 26, 9, 20);

    final checks = generateAdaptiveSchedule(
      classStart: start,
      classEnd: end,
      random: Random(42),
    );

    expect(checks.length, greaterThanOrEqualTo(2));
    expect(checks.first, equals(start));
    expect(checks.last, equals(end));
  });

  test('Long class (3 hours) produces reasonable number of checks', () {
    final start = DateTime(2026, 9, 26, 9, 0);
    final end = DateTime(2026, 9, 26, 12, 0);

    final checks = generateAdaptiveSchedule(
      classStart: start,
      classEnd: end,
      random: Random(42),
    );

    // Should have 5 checks even for long classes (not excessive)
    expect(checks.length, greaterThanOrEqualTo(4));
    expect(checks.length, lessThanOrEqualTo(6));
  });

  test('No checks are less than 30 seconds apart (deduplication)', () {
    final start = DateTime(2026, 9, 26, 9, 0);
    final end = DateTime(2026, 9, 26, 10, 0);

    // Run with many different seeds to stress-test deduplication
    for (int seed = 0; seed < 50; seed++) {
      final checks = generateAdaptiveSchedule(
        classStart: start,
        classEnd: end,
        random: Random(seed),
      );

      for (int i = 1; i < checks.length; i++) {
        expect(
          checks[i].difference(checks[i - 1]).inSeconds,
          greaterThanOrEqualTo(30),
          reason: 'Seed $seed: checks $i and ${i - 1} too close',
        );
      }
    }
  });

  // --- describeSchedule (logging helper) ---

  test('describeSchedule produces readable output', () {
    final start = DateTime(2026, 9, 26, 9, 0);
    final end = DateTime(2026, 9, 26, 10, 0);

    final checks = generateAdaptiveSchedule(
      classStart: start,
      classEnd: end,
      random: Random(42),
    );

    final desc = describeSchedule(start, end, checks);
    expect(desc, contains('60min class'));
    expect(desc, contains('09:00'));
    expect(desc, contains('10:00'));
    expect(desc, contains('START'));
    expect(desc, contains('END'));
  });
}
