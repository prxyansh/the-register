// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_entries_dao.dart';

// ignore_for_file: type=lint
mixin _$TimetableEntriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $SubjectsTable get subjects => attachedDatabase.subjects;
  $VenuesTable get venues => attachedDatabase.venues;
  $TimetableEntriesTable get timetableEntries =>
      attachedDatabase.timetableEntries;
  TimetableEntriesDaoManager get managers => TimetableEntriesDaoManager(this);
}

class TimetableEntriesDaoManager {
  final _$TimetableEntriesDaoMixin _db;
  TimetableEntriesDaoManager(this._db);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db.attachedDatabase, _db.subjects);
  $$VenuesTableTableManager get venues =>
      $$VenuesTableTableManager(_db.attachedDatabase, _db.venues);
  $$TimetableEntriesTableTableManager get timetableEntries =>
      $$TimetableEntriesTableTableManager(
        _db.attachedDatabase,
        _db.timetableEntries,
      );
}
