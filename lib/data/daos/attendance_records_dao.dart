import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'attendance_records_dao.g.dart';

/// DAO for CRUD operations on the AttendanceRecords table.
/// Updated for two-field model per attendance-rules.md §1.
@DriftAccessor(tables: [AttendanceRecords, TimetableEntries])
class AttendanceRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$AttendanceRecordsDaoMixin {
  AttendanceRecordsDao(super.db);

  /// Get all records as a reactive stream.
  Stream<List<AttendanceRecord>> watchAllRecords() =>
      select(attendanceRecords).watch();

  /// Get all records (one-shot, for export).
  Future<List<AttendanceRecord>> getAllRecords() =>
      select(attendanceRecords).get();

  /// Get records for a specific date (today's classes).
  Future<List<AttendanceRecord>> getRecordsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(attendanceRecords)
          ..where((r) =>
              r.date.isBiggerOrEqualValue(startOfDay) &
              r.date.isSmallerThanValue(endOfDay)))
        .get();
  }

  /// Watch records for a specific date (reactive, for Today screen).
  Stream<List<AttendanceRecord>> watchRecordsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(attendanceRecords)
          ..where((r) =>
              r.date.isBiggerOrEqualValue(startOfDay) &
              r.date.isSmallerThanValue(endOfDay)))
        .watch();
  }

  /// Watch records for a specific date range (for Calendar screen).
  Stream<List<AttendanceRecord>> watchRecordsForDateRange(DateTime start, DateTime end) {
    return (select(attendanceRecords)
          ..where((r) =>
              r.date.isBiggerOrEqualValue(start) &
              r.date.isSmallerThanValue(end)))
        .watch();
  }

  /// Get all records for a specific timetable entry (for reports).
  Future<List<AttendanceRecord>> getRecordsForEntry(int timetableEntryId) =>
      (select(attendanceRecords)
            ..where((r) => r.timetableEntryId.equals(timetableEntryId))
            ..orderBy([(r) => OrderingTerm.desc(r.date)]))
          .get();

  /// Watch records for a specific timetable entry (reactive).
  Stream<List<AttendanceRecord>> watchRecordsForEntry(int timetableEntryId) =>
      (select(attendanceRecords)
            ..where((r) => r.timetableEntryId.equals(timetableEntryId))
            ..orderBy([(r) => OrderingTerm.desc(r.date)]))
          .watch();

  /// Get a single record by ID.
  Future<AttendanceRecord> getRecordById(int id) =>
      (select(attendanceRecords)..where((r) => r.id.equals(id))).getSingle();

  /// Insert a new attendance record, returns the generated ID.
  Future<int> insertRecord(AttendanceRecordsCompanion record) =>
      into(attendanceRecords).insert(record);

  /// Update an existing record.
  Future<bool> updateRecord(AttendanceRecord record) =>
      update(attendanceRecords).replace(record);

  /// Delete a record by ID.
  Future<int> deleteRecordById(int id) =>
      (delete(attendanceRecords)..where((r) => r.id.equals(id))).go();

  /// Override a record's status and classification with a reason.
  /// Per attendance-rules.md §3: manual override updates both fields.
  Future<void> overrideRecord(
      int id, String newAttendanceStatus, String newClassification, String? reason) =>
      (update(attendanceRecords)..where((r) => r.id.equals(id))).write(
        AttendanceRecordsCompanion(
          attendanceStatus: Value(newAttendanceStatus),
          classification: Value(newClassification),
          overrideReason: Value(reason),
        ),
      );

  /// Update detection result from the attendance checker (GPS/WiFi/motion).
  /// Only updates attendance_status, confidence, and checks — classification
  /// stays at whatever it was set to (default: 'normal').
  Future<void> updateDetectionResult(
      int id, double confidenceScore, String attendanceStatus, String checksJson) =>
      (update(attendanceRecords)..where((r) => r.id.equals(id))).write(
        AttendanceRecordsCompanion(
          confidenceScore: Value(confidenceScore),
          attendanceStatus: Value(attendanceStatus),
          checksJson: Value(checksJson),
        ),
      );

  /// Mark a single class occurrence as cancelled (reactive path — §4).
  /// The attendance_status stays as-is for historical accuracy,
  /// but classification='cancelled' removes it from the percentage.
  Future<void> markCancelled(int id) =>
      (update(attendanceRecords)..where((r) => r.id.equals(id))).write(
        const AttendanceRecordsCompanion(
          classification: Value('cancelled'),
        ),
      );

  /// Mark a record as excused with a reason.
  /// Per attendance-rules.md §6: how this affects % depends on user setting.
  Future<void> markExcused(int id, String reason) =>
      (update(attendanceRecords)..where((r) => r.id.equals(id))).write(
        AttendanceRecordsCompanion(
          classification: const Value('excused'),
          overrideReason: Value(reason),
        ),
      );

  /// Get all unresolved records (ambiguous or unknown) older than a threshold.
  /// Per attendance-rules.md §5: 48-hour auto-resolve rule.
  Future<List<AttendanceRecord>> getStaleUnresolvedRecords(Duration threshold) {
    final cutoff = DateTime.now().subtract(threshold);
    return (select(attendanceRecords)
          ..where((r) =>
              (r.attendanceStatus.equals('ambiguous') |
                  r.attendanceStatus.equals('unknown')) &
              r.date.isSmallerThanValue(cutoff) &
              r.autoResolved.equals(false)))
        .get();
  }

  /// Auto-resolve a stale record per §5.
  /// Resolves to the given status and marks it as auto-resolved.
  Future<void> autoResolve(int id, String resolvedStatus) =>
      (update(attendanceRecords)..where((r) => r.id.equals(id))).write(
        AttendanceRecordsCompanion(
          attendanceStatus: Value(resolvedStatus),
          autoResolved: const Value(true),
        ),
      );

  /// Update classification for a record (e.g., normal → cancelled).
  Future<void> updateClassification(int id, String newClassification) =>
      (update(attendanceRecords)..where((r) => r.id.equals(id))).write(
        AttendanceRecordsCompanion(
          classification: Value(newClassification),
        ),
      );
}
