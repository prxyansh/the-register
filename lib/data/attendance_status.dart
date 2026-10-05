/// Attendance status enum — what the detection engine observed.
/// Per attendance-rules.md §1: split from old single-field model.
///
/// This answers: "Was the student physically present?"
enum AttendanceStatus {
  present,
  absent,
  ambiguous,
  unknown;

  /// Convert to database-storable string.
  String toDbValue() {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.ambiguous:
        return 'ambiguous';
      case AttendanceStatus.unknown:
        return 'unknown';
    }
  }

  /// Parse from database string.
  static AttendanceStatus fromDbValue(String value) {
    switch (value) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'ambiguous':
        return AttendanceStatus.ambiguous;
      case 'unknown':
        return AttendanceStatus.unknown;
      // --- Migration compatibility ---
      // Old records stored 'manual_override' as a status.
      // After migration, these get classification='excused' and
      // status='absent', but if any old value leaks through, map
      // it to 'present' (the old behavior for overrides without reason).
      case 'manual_override':
        return AttendanceStatus.present;
      default:
        throw ArgumentError('Unknown AttendanceStatus: $value');
    }
  }
}

/// Record classification — does this record count toward the attendance %?
/// Per attendance-rules.md §1.
///
/// This answers: "Should this occurrence affect the percentage?"
enum RecordClassification {
  /// Normal scheduled class — counts toward %.
  normal,

  /// Class was cancelled (prof absent, etc.) — excluded from %.
  cancelled,

  /// Campus-wide holiday — no record should even exist, but if it does,
  /// it's excluded from %.
  holiday,

  /// Excused absence (sick, official leave) — behavior depends on
  /// user's `excused_counts_as` setting (§6).
  excused,

  /// Extra / makeup class — counts toward % just like normal (§9).
  extraSession;

  /// Convert to database-storable string.
  String toDbValue() {
    switch (this) {
      case RecordClassification.normal:
        return 'normal';
      case RecordClassification.cancelled:
        return 'cancelled';
      case RecordClassification.holiday:
        return 'holiday';
      case RecordClassification.excused:
        return 'excused';
      case RecordClassification.extraSession:
        return 'extra_session';
    }
  }

  /// Parse from database string.
  static RecordClassification fromDbValue(String value) {
    switch (value) {
      case 'normal':
        return RecordClassification.normal;
      case 'cancelled':
        return RecordClassification.cancelled;
      case 'holiday':
        return RecordClassification.holiday;
      case 'excused':
        return RecordClassification.excused;
      case 'extra_session':
        return RecordClassification.extraSession;
      default:
        return RecordClassification.normal; // Safe default for old data
    }
  }
}

/// How excused absences are treated in percentage calculations.
/// Per attendance-rules.md §6.
enum ExcusedCountsAs {
  /// Option A — excused absences don't count (excluded from denominator).
  /// Recommended default.
  excluded,

  /// Option B — excused absences count as attended (status forced to present).
  present,

  /// Option C — excused absences count as absent (strictest, most honest).
  absent;

  String toDbValue() => name;

  static ExcusedCountsAs fromDbValue(String value) {
    switch (value) {
      case 'excluded':
        return ExcusedCountsAs.excluded;
      case 'present':
        return ExcusedCountsAs.present;
      case 'absent':
        return ExcusedCountsAs.absent;
      default:
        return ExcusedCountsAs.excluded; // Default per §6
    }
  }

  /// Human-readable label for settings UI.
  String get label {
    switch (this) {
      case ExcusedCountsAs.excluded:
        return 'Don\'t count (excluded from %)';
      case ExcusedCountsAs.present:
        return 'Count as present';
      case ExcusedCountsAs.absent:
        return 'Count as absent';
    }
  }

  /// Short description for settings UI.
  String get description {
    switch (this) {
      case ExcusedCountsAs.excluded:
        return 'Medical/official leave is removed from your total, as if the class never happened.';
      case ExcusedCountsAs.present:
        return 'Medical/official leave counts as if you attended the class.';
      case ExcusedCountsAs.absent:
        return 'Medical/official leave still counts as absent — tracks honest reality.';
    }
  }
}
