import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/domain/report_calculator.dart';
import 'package:attendance_tracker/data/app_database.dart';

/// Tests for report calculator — SPEC §10 Screen 5.
/// Hand-calculated examples verify mathematical correctness.
void main() {
  // Helper to create a minimal Subject for testing
  Subject makeSubject({
    int id = 1,
    String name = 'Math',
    int color = 0xFF2196F3,
    double targetPct = 75.0,
  }) {
    return Subject(
      id: id,
      name: name,
      color: color,
      targetAttendancePct: targetPct,
    );
  }

  // Helper to create an AttendanceRecord for testing
  AttendanceRecord makeRecord({
    int id = 1,
    int timetableEntryId = 1,
    required DateTime date,
    required String status,
    double confidenceScore = 0.0,
    String checksJson = '[]',
    String? overrideReason,
  }) {
    return AttendanceRecord(
      id: id,
      timetableEntryId: timetableEntryId,
      date: date,
      status: status,
      confidenceScore: confidenceScore,
      checksJson: checksJson,
      overrideReason: overrideReason,
    );
  }

  TimetableEntry makeEntry({
    int id = 1,
    int subjectId = 1,
    int dayOfWeek = 1,
    String startTime = '09:00',
    String endTime = '10:00',
    bool active = true,
    int? venueId,
  }) {
    return TimetableEntry(
      id: id,
      subjectId: subjectId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      active: active,
      venueId: venueId,
    );
  }

  // --- Attendance Percentage ---

  test('Hand-calculated: 8 present out of 10 = 80%', () {
    final subject = makeSubject(targetPct: 75);
    final entries = [makeEntry(id: 1, subjectId: 1)];
    final records = List.generate(10, (i) => makeRecord(
          id: i + 1,
          timetableEntryId: 1,
          date: DateTime(2026, 9, i + 1),
          status: i < 8 ? 'present' : 'absent',
        ));

    final reports = computeReports(
      subjects: [subject],
      entries: entries,
      records: records,
    );

    expect(reports.length, 1);
    expect(reports[0].totalScheduled, 10);
    expect(reports[0].presentCount, 8);
    expect(reports[0].absentCount, 2);
    expect(reports[0].attendancePct, closeTo(80.0, 0.1));
  });

  test('No records → 100% (nothing to count against)', () {
    final subject = makeSubject();
    final reports = computeReports(
      subjects: [subject],
      entries: [makeEntry()],
      records: [],
    );

    expect(reports[0].attendancePct, 100.0);
  });

  // --- Excused Classes ---

  test('Excused classes excluded from denominator', () {
    // 10 total, 2 excused → effective = 8
    // 6 present out of 8 = 75%
    final subject = makeSubject(targetPct: 75);
    final entries = [makeEntry(id: 1, subjectId: 1)];
    final records = [
      // 6 present
      ...List.generate(6, (i) => makeRecord(
            id: i + 1,
            timetableEntryId: 1,
            date: DateTime(2026, 9, i + 1),
            status: 'present',
          )),
      // 2 absent
      ...List.generate(2, (i) => makeRecord(
            id: i + 7,
            timetableEntryId: 1,
            date: DateTime(2026, 9, i + 7),
            status: 'absent',
          )),
      // 2 excused (manual_override with reason)
      ...List.generate(2, (i) => makeRecord(
            id: i + 9,
            timetableEntryId: 1,
            date: DateTime(2026, 9, i + 9),
            status: 'manual_override',
            overrideReason: 'sick',
          )),
    ];

    final reports = computeReports(
      subjects: [subject],
      entries: entries,
      records: records,
    );

    expect(reports[0].totalScheduled, 10);
    expect(reports[0].excusedCount, 2);
    // 6 present / (10 - 2 excused) = 6/8 = 75%
    expect(reports[0].attendancePct, closeTo(75.0, 0.1));
  });

  // --- Bunk Budget ---

  test('Hand-calculated bunk budget: 8/10 present, 75% target → can miss 1 more', () {
    // effective = 10, target = 75%, minRequired = ceil(7.5) = 8
    // budget = 8 - 8 = 0
    // Wait, let's recalculate: present=8, total=10, excused=0
    // minRequired = ceil(0.75 * 10) = 8
    // projectedPresent = 8 + 0 future = 8
    // budget = 8 - 8 = 0 → exactly on target
    final report = SubjectReport(
      subject: makeSubject(targetPct: 75),
      totalScheduled: 10,
      presentCount: 8,
      absentCount: 2,
      ambiguousCount: 0,
      excusedCount: 0,
    );

    expect(report.bunkBudget(), 0); // exactly at target, can't miss any more
    expect(report.isAboveTarget, true); // 80% >= 75%
  });

  test('Bunk budget with future classes: can miss more if future assumed present', () {
    // 8 present out of 10 so far, 5 future classes remaining
    // effective = 10 + 5 = 15
    // minRequired = ceil(0.75 * 15) = 12
    // projectedPresent = 8 + 5 = 13
    // budget = 13 - 12 = 1 → can miss 1 more
    final report = SubjectReport(
      subject: makeSubject(targetPct: 75),
      totalScheduled: 10,
      presentCount: 8,
      absentCount: 2,
      ambiguousCount: 0,
      excusedCount: 0,
    );

    expect(report.bunkBudget(futureClassesRemaining: 5), 1);
  });

  test('Bunk budget negative when below target', () {
    // 5 present out of 10, target 75%
    // minRequired = ceil(0.75 * 10) = 8
    // budget = 5 - 8 = -3 → 3 short of target
    final report = SubjectReport(
      subject: makeSubject(targetPct: 75),
      totalScheduled: 10,
      presentCount: 5,
      absentCount: 5,
      ambiguousCount: 0,
      excusedCount: 0,
    );

    expect(report.bunkBudget(), -3);
    expect(report.isAboveTarget, false); // 50% < 75%
  });

  // --- Multiple Subjects ---

  test('Multiple subjects computed independently', () {
    final math = makeSubject(id: 1, name: 'Math', targetPct: 75);
    final physics = makeSubject(id: 2, name: 'Physics', targetPct: 80);

    final entries = [
      makeEntry(id: 1, subjectId: 1),
      makeEntry(id: 2, subjectId: 2),
    ];

    final records = [
      // Math: 3 present, 1 absent
      ...List.generate(3, (i) => makeRecord(
            id: i + 1,
            timetableEntryId: 1,
            date: DateTime(2026, 9, i + 1),
            status: 'present',
          )),
      makeRecord(
          id: 4, timetableEntryId: 1,
          date: DateTime(2026, 9, 4), status: 'absent'),
      // Physics: 4 present, 1 absent
      ...List.generate(4, (i) => makeRecord(
            id: i + 5,
            timetableEntryId: 2,
            date: DateTime(2026, 9, i + 1),
            status: 'present',
          )),
      makeRecord(
          id: 9, timetableEntryId: 2,
          date: DateTime(2026, 9, 5), status: 'absent'),
    ];

    final reports = computeReports(
      subjects: [math, physics],
      entries: entries,
      records: records,
    );

    expect(reports.length, 2);
    // Math: 3/4 = 75%
    expect(reports[0].attendancePct, closeTo(75.0, 0.1));
    // Physics: 4/5 = 80%
    expect(reports[1].attendancePct, closeTo(80.0, 0.1));
  });

  // --- Weekly Trend ---

  test('Weekly trend groups records by Monday-based weeks', () {
    final records = [
      // Week of Sep 22 (Monday)
      makeRecord(id: 1, date: DateTime(2026, 9, 22), status: 'present'),
      makeRecord(id: 2, date: DateTime(2026, 9, 23), status: 'present'),
      makeRecord(id: 3, date: DateTime(2026, 9, 24), status: 'absent'),
      // Week of Sep 29 (Monday)
      makeRecord(id: 4, date: DateTime(2026, 9, 29), status: 'present'),
      makeRecord(id: 5, date: DateTime(2026, 9, 30), status: 'absent'),
    ];

    final trends = computeWeeklyTrend(records);

    expect(trends.length, 2);
    // Week 1: 2 present out of 3
    expect(trends[0].totalClasses, 3);
    expect(trends[0].presentClasses, 2);
    expect(trends[0].attendancePct, closeTo(66.7, 0.1));
    // Week 2: 1 present out of 2
    expect(trends[1].totalClasses, 2);
    expect(trends[1].presentClasses, 1);
    expect(trends[1].attendancePct, closeTo(50.0, 0.1));
  });

  test('Empty records → empty trend', () {
    expect(computeWeeklyTrend([]), isEmpty);
  });
}
