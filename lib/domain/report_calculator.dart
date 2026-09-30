import '../data/app_database.dart';
import '../data/attendance_status.dart';

// Attendance report computation — SPEC.md §10, Screen 5.
//
// Per-subject attendance percentage, bunk budget, and trend data.
// All calculations are pure functions for easy testing.

/// Summary statistics for a single subject.
class SubjectReport {
  final Subject subject;
  final int totalScheduled;
  final int presentCount;
  final int absentCount;
  final int ambiguousCount;
  final int excusedCount; // manual_override marked as excused

  SubjectReport({
    required this.subject,
    required this.totalScheduled,
    required this.presentCount,
    required this.absentCount,
    required this.ambiguousCount,
    required this.excusedCount,
  });

  /// Attendance percentage: present / (total - excused).
  /// Excused classes are excluded from the denominator per spec.
  double get attendancePct {
    final effective = totalScheduled - excusedCount;
    if (effective <= 0) return 100.0;
    return (presentCount / effective) * 100.0;
  }

  /// Bunk budget: how many more classes can be missed while staying
  /// at or above the subject's `target_attendance_pct`.
  ///
  /// Formula:
  ///   present >= target% * (total - excused + future_classes)
  ///   We solve for max additional absences given current state.
  ///   budget = present - ceil(target% * effective_total)
  ///   (negative = already below target)
  int bunkBudget({int futureClassesRemaining = 0}) {
    final targetPct = subject.targetAttendancePct / 100.0;
    final effective = totalScheduled - excusedCount + futureClassesRemaining;
    if (effective <= 0) return 0;
    final minRequired = (targetPct * effective).ceil();
    // Assume future classes will be attended
    final projectedPresent = presentCount + futureClassesRemaining;
    return projectedPresent - minRequired;
  }

  /// Whether the student is currently above their attendance target.
  bool get isAboveTarget => attendancePct >= subject.targetAttendancePct;
}

/// Compute reports for all subjects given their entries and records.
List<SubjectReport> computeReports({
  required List<Subject> subjects,
  required List<TimetableEntry> entries,
  required List<AttendanceRecord> records,
}) {
  return subjects.map((subject) {
    // Count total scheduled classes for this subject
    // Each record = one class occurrence
    final subjectEntries =
        entries.where((e) => e.subjectId == subject.id).toList();
    final subjectEntryIds = subjectEntries.map((e) => e.id).toSet();

    final subjectRecords =
        records.where((r) => subjectEntryIds.contains(r.timetableEntryId)).toList();

    int present = 0;
    int absent = 0;
    int ambiguous = 0;
    int excused = 0;

    for (final record in subjectRecords) {
      final status = AttendanceStatus.fromDbValue(record.status);
      switch (status) {
        case AttendanceStatus.present:
          present++;
        case AttendanceStatus.absent:
          absent++;
        case AttendanceStatus.ambiguous:
          ambiguous++;
        case AttendanceStatus.manualOverride:
          // Check if this is an excused override
          if (record.overrideReason != null) {
            excused++;
          } else {
            present++; // Override without reason = counted as present
          }
      }
    }

    return SubjectReport(
      subject: subject,
      totalScheduled: subjectRecords.length,
      presentCount: present,
      absentCount: absent,
      ambiguousCount: ambiguous,
      excusedCount: excused,
    );
  }).toList();
}

/// Weekly trend data point.
class WeeklyTrend {
  final DateTime weekStart;
  final int totalClasses;
  final int presentClasses;

  WeeklyTrend({
    required this.weekStart,
    required this.totalClasses,
    required this.presentClasses,
  });

  double get attendancePct {
    if (totalClasses == 0) return 0.0;
    return (presentClasses / totalClasses) * 100.0;
  }
}

/// Compute weekly trend from records.
List<WeeklyTrend> computeWeeklyTrend(List<AttendanceRecord> records) {
  if (records.isEmpty) return [];

  // Group records by week (Monday-based)
  final Map<DateTime, List<AttendanceRecord>> byWeek = {};
  for (final record in records) {
    final monday = record.date.subtract(
        Duration(days: record.date.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    byWeek.putIfAbsent(weekStart, () => []).add(record);
  }

  // Convert to trend data, sorted by date
  final trends = byWeek.entries.map((entry) {
    final weekRecords = entry.value;
    final present = weekRecords.where((r) {
      final status = AttendanceStatus.fromDbValue(r.status);
      return status == AttendanceStatus.present;
    }).length;
    return WeeklyTrend(
      weekStart: entry.key,
      totalClasses: weekRecords.length,
      presentClasses: present,
    );
  }).toList();

  trends.sort((a, b) => a.weekStart.compareTo(b.weekStart));
  return trends;
}
