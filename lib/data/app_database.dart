import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';
import 'daos/subjects_dao.dart';
import 'daos/venues_dao.dart';
import 'daos/timetable_entries_dao.dart';
import 'daos/attendance_records_dao.dart';

part 'app_database.g.dart';

/// Main application database.
/// Includes all four tables from SPEC.md §4 and their DAOs.
@DriftDatabase(
  tables: [Subjects, Venues, TimetableEntries, AttendanceRecords],
  daos: [SubjectsDao, VenuesDao, TimetableEntriesDao, AttendanceRecordsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'attendance_tracker'));

  @override
  int get schemaVersion => 1;
}
