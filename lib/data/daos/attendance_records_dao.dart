import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'attendance_records_dao.g.dart';

/// DAO for CRUD operations on the AttendanceRecords table.
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

  /// Update status and override reason (for manual override — Task 9).
  Future<void> overrideRecord(
      int id, String status, String? reason) =>
      (update(attendanceRecords)..where((r) => r.id.equals(id))).write(
        AttendanceRecordsCompanion(
          status: Value(status),
          overrideReason: Value(reason),
        ),
      );

  /// Update confidence score and checks JSON (for detection engine — Task 5).
  Future<void> updateDetectionResult(
      int id, double confidenceScore, String status, String checksJson) =>
      (update(attendanceRecords)..where((r) => r.id.equals(id))).write(
        AttendanceRecordsCompanion(
          confidenceScore: Value(confidenceScore),
          status: Value(status),
          checksJson: Value(checksJson),
        ),
      );
}
