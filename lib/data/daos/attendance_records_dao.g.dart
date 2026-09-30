// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_records_dao.dart';

// ignore_for_file: type=lint
mixin _$AttendanceRecordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SubjectsTable get subjects => attachedDatabase.subjects;
  $VenuesTable get venues => attachedDatabase.venues;
  $TimetableEntriesTable get timetableEntries =>
      attachedDatabase.timetableEntries;
  $AttendanceRecordsTable get attendanceRecords =>
      attachedDatabase.attendanceRecords;
  AttendanceRecordsDaoManager get managers => AttendanceRecordsDaoManager(this);
}

class AttendanceRecordsDaoManager {
  final _$AttendanceRecordsDaoMixin _db;
  AttendanceRecordsDaoManager(this._db);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db.attachedDatabase, _db.subjects);
  $$VenuesTableTableManager get venues =>
      $$VenuesTableTableManager(_db.attachedDatabase, _db.venues);
  $$TimetableEntriesTableTableManager get timetableEntries =>
      $$TimetableEntriesTableTableManager(
        _db.attachedDatabase,
        _db.timetableEntries,
      );
  $$AttendanceRecordsTableTableManager get attendanceRecords =>
      $$AttendanceRecordsTableTableManager(
        _db.attachedDatabase,
        _db.attendanceRecords,
      );
}
