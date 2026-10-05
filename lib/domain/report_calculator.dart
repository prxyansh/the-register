import '../data/app_database.dart';
import '../data/attendance_status.dart';

// Attendance report computation — attendance-rules.md §2 (Master Rule).
//
// Per-subject attendance percentage, bunk budget, and trend data.
// All calculations are pure functions for easy testing.
//
// MASTER RULE: A record counts toward % only if:
//   classification = normal OR extra_session
//   AND attendance_status = present OR absent (not ambiguous/unknown)

/// Summary statistics for a single subject.
class SubjectReport {
  final Subject subject;
  final int totalCounted;     // Records that count toward % (denominator)
  final int presentCount;     // Present records in countable pool
  final int absentCount;      // Absent records in countable pool
  final int ambiguousCount;   // Unresolved — not counted yet
  final int cancelledCount;   // Cancelled classes — excluded from %
  final int excusedCount;     // Excused absences — behavior varies by setting
  final int extraSessionCount; // Extra/makeup classes attended

  SubjectReport({
    required this.subject,
    required this.totalCounted,
    required this.presentCount,
    required this.absentCount,
    required this.ambiguousCount,
    required this.cancelledCount,
    required this.excusedCount,
    required this.extraSessionCount,
  });

  /// Attendance percentage using the master rule.
  double get attendancePct {
    if (totalCounted <= 0) return 100.0;
    return (presentCount / totalCounted) * 100.0;
  }

  /// Bunk budget: how many more classes can be missed while staying
  /// at or above the subject's `target_attendance_pct`.
  ///
  /// Formula:
  ///   present >= target% * (totalCounted + futureClasses)
  ///   budget = present + futureClasses - ceil(target% * (totalCounted + futureClasses))
  ///   (negative = already below target)
  int bunkBudget({int futureClassesRemaining = 0}) {
    final targetPct = subject.targetAttendancePct / 100.0;
    final projected = totalCounted + futureClassesRemaining;
    if (projected <= 0) return 0;
    final minRequired = (targetPct * projected).ceil();
    // Assume future classes will be attended
    final projectedPresent = presentCount + futureClassesRemaining;
    return projectedPresent - minRequired;
  }

  /// Whether the student is currently above their attendance target.
  bool get isAboveTarget => attendancePct >= subject.targetAttendancePct;

  /// Total records across all classifications (for context).
  int get totalRecords =>
      totalCounted + ambiguousCount + cancelledCount + excusedCount;
}

/// Compute reports for all subjects given their entries and records.
///
/// Implements the MASTER RULE from attendance-rules.md §2:
/// - Only records with classification = normal | extra_session count
/// - Only records with attendance_status = present | absent count
/// - Excused handling depends on [excusedPolicy]
List<SubjectReport> computeReports({
  required List<Subject> subjects,
  required List<TimetableEntry> entries,
  required List<AttendanceRecord> records,
  ExcusedCountsAs excusedPolicy = ExcusedCountsAs.excluded,
}) {
  return subjects.map((subject) {
    // Find all timetable entry IDs for this subject
    final subjectEntries =
        entries.where((e) => e.subjectId == subject.id).toList();
    final subjectEntryIds = subjectEntries.map((e) => e.id).toSet();

    final subjectRecords =
        records.where((r) => subjectEntryIds.contains(r.timetableEntryId)).toList();

    int present = 0;
    int absent = 0;
    int ambiguous = 0;
    int cancelled = 0;
    int excused = 0;
    int extraSession = 0;

    for (final record in subjectRecords) {
      final status = AttendanceStatus.fromDbValue(record.attendanceStatus);
      final classification = RecordClassification.fromDbValue(record.classification);

      // --- Classification-based routing ---
      switch (classification) {
        case RecordClassification.cancelled:
          cancelled++;
          continue; // Never counts toward %

        case RecordClassification.holiday:
          continue; // Should not even have records, but skip if present

        case RecordClassification.excused:
          excused++;
          // Apply the user's excused policy (§6)
          switch (excusedPolicy) {
            case ExcusedCountsAs.excluded:
              continue; // Remove from denominator entirely (Option A)
            case ExcusedCountsAs.present:
              present++; // Count as attended (Option B)
              break;
            case ExcusedCountsAs.absent:
              absent++; // Count as absent (Option C)
              break;
          }
          break;

        case RecordClassification.extraSession:
          extraSession++;
          // Falls through to normal counting below
          break;

        case RecordClassification.normal:
          break; // Falls through to normal counting below
      }

      // --- Status-based counting (only for normal + extra_session) ---
      // Master rule: only resolved statuses count
      if (classification == RecordClassification.excused) {
        // Already handled above — don't double-count
        continue;
      }

      switch (status) {
        case AttendanceStatus.present:
          present++;
        case AttendanceStatus.absent:
          absent++;
        case AttendanceStatus.ambiguous:
        case AttendanceStatus.unknown:
          ambiguous++; // Not counted until resolved
      }
    }

    return SubjectReport(
      subject: subject,
      totalCounted: present + absent, // Only resolved, countable records
      presentCount: present,
      absentCount: absent,
      ambiguousCount: ambiguous,
      cancelledCount: cancelled,
      excusedCount: excused,
      extraSessionCount: extraSession,
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
/// Only counts records that pass the master rule (normal/extra_session + resolved).
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

    // Only count records that pass the master rule
    final countable = weekRecords.where((r) {
      final classification = RecordClassification.fromDbValue(r.classification);
      final status = AttendanceStatus.fromDbValue(r.attendanceStatus);
      return (classification == RecordClassification.normal ||
              classification == RecordClassification.extraSession) &&
          (status == AttendanceStatus.present ||
              status == AttendanceStatus.absent);
    }).toList();

    final presentCount = countable.where((r) {
      return AttendanceStatus.fromDbValue(r.attendanceStatus) ==
          AttendanceStatus.present;
    }).length;

    return WeeklyTrend(
      weekStart: entry.key,
      totalClasses: countable.length,
      presentClasses: presentCount,
    );
  }).toList();

  trends.sort((a, b) => a.weekStart.compareTo(b.weekStart));
  return trends;
}
