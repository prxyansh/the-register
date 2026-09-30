/// Attendance status enum matching SPEC.md §4.
/// Used in AttendanceRecords.status field.
enum AttendanceStatus {
  present,
  absent,
  ambiguous,
  manualOverride;

  /// Convert to database-storable string.
  String toDbValue() {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.ambiguous:
        return 'ambiguous';
      case AttendanceStatus.manualOverride:
        return 'manual_override';
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
      case 'manual_override':
        return AttendanceStatus.manualOverride;
      default:
        throw ArgumentError('Unknown AttendanceStatus: $value');
    }
  }
}
