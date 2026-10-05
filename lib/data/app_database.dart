import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';
import 'daos/subjects_dao.dart';
import 'daos/venues_dao.dart';
import 'daos/timetable_entries_dao.dart';
import 'daos/attendance_records_dao.dart';
import 'daos/holidays_dao.dart';

part 'app_database.g.dart';

/// Main application database.
/// Includes all tables from SPEC.md §4 + attendance-rules.md extensions.
///
/// Schema v3 changes (attendance-rules.md):
/// - AttendanceRecords: split `status` → `attendance_status` + `classification`
/// - AttendanceRecords: added `auto_resolved` flag
/// - New table: Holidays (campus-wide closures)
///
/// Schema v4 changes (academic calendar):
/// - Holidays: added `event_type`, `end_date`, `follows_day` columns
@DriftDatabase(
  tables: [Subjects, Venues, TimetableEntries, AttendanceRecords, Holidays],
  daos: [SubjectsDao, VenuesDao, TimetableEntriesDao, AttendanceRecordsDao, HolidaysDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'attendance_tracker'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(subjects, subjects.facultyName);
          }
          if (from < 3) {
            // --- attendance-rules.md migration ---

            // 1. Add the new columns to AttendanceRecords
            await m.addColumn(
                attendanceRecords, attendanceRecords.attendanceStatus);
            await m.addColumn(
                attendanceRecords, attendanceRecords.classification);
            await m.addColumn(
                attendanceRecords, attendanceRecords.autoResolved);

            // 2. Migrate data from old `status` column to new fields.
            //    - 'present' / 'absent' / 'ambiguous' → attendanceStatus = same, classification = 'normal'
            //    - 'manual_override' with reason → attendanceStatus = 'absent', classification = 'excused'
            //    - 'manual_override' without reason → attendanceStatus = 'present', classification = 'normal'
            await customStatement('''
              UPDATE attendance_records SET
                attendance_status = CASE
                  WHEN status = 'manual_override' AND override_reason IS NOT NULL THEN 'absent'
                  WHEN status = 'manual_override' THEN 'present'
                  ELSE status
                END,
                classification = CASE
                  WHEN status = 'manual_override' AND override_reason IS NOT NULL THEN 'excused'
                  ELSE 'normal'
                END,
                auto_resolved = 0
            ''');

            // 3. Create the Holidays table
            await m.createTable(holidays);
          }
          if (from < 4) {
            // --- Academic calendar migration ---
            // Add new columns for event types, date ranges, and compensatory days
            await m.addColumn(holidays, holidays.endDate);
            await m.addColumn(holidays, holidays.eventType);
            await m.addColumn(holidays, holidays.followsDay);
          }
        },
      );
}
