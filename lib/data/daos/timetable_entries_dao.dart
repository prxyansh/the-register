import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'timetable_entries_dao.g.dart';

/// DAO for CRUD operations on the TimetableEntries table.
@DriftAccessor(tables: [TimetableEntries, Subjects, Venues])
class TimetableEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$TimetableEntriesDaoMixin {
  TimetableEntriesDao(super.db);

  /// Get all timetable entries as a reactive stream.
  Stream<List<TimetableEntry>> watchAllEntries() =>
      select(timetableEntries).watch();

  /// Get all timetable entries (one-shot).
  Future<List<TimetableEntry>> getAllEntries() =>
      select(timetableEntries).get();

  /// Get entries for a specific day of the week.
  Future<List<TimetableEntry>> getEntriesForDay(int dayOfWeek) =>
      (select(timetableEntries)
            ..where((e) => e.dayOfWeek.equals(dayOfWeek))
            ..where((e) => e.active.equals(true))
            ..orderBy([
              (e) => OrderingTerm.asc(e.startTime),
            ]))
          .get();

  /// Watch entries for a specific day (reactive).
  Stream<List<TimetableEntry>> watchEntriesForDay(int dayOfWeek) =>
      (select(timetableEntries)
            ..where((e) => e.dayOfWeek.equals(dayOfWeek))
            ..where((e) => e.active.equals(true))
            ..orderBy([
              (e) => OrderingTerm.asc(e.startTime),
            ]))
          .watch();

  /// Get a single entry by ID.
  Future<TimetableEntry> getEntryById(int id) =>
      (select(timetableEntries)..where((e) => e.id.equals(id))).getSingle();

  /// Insert a new timetable entry, returns the generated ID.
  Future<int> insertEntry(TimetableEntriesCompanion entry) =>
      into(timetableEntries).insert(entry);

  /// Update an existing entry.
  Future<bool> updateEntry(TimetableEntry entry) =>
      update(timetableEntries).replace(entry);

  /// Delete an entry by ID.
  Future<int> deleteEntryById(int id) =>
      (delete(timetableEntries)..where((e) => e.id.equals(id))).go();

  /// Toggle active status (for holidays/exceptions).
  Future<void> toggleActive(int id, bool active) =>
      (update(timetableEntries)..where((e) => e.id.equals(id)))
          .write(TimetableEntriesCompanion(active: Value(active)));

  /// Link a venue to a timetable entry (Task 3).
  Future<void> setVenue(int entryId, int? venueId) =>
      (update(timetableEntries)..where((e) => e.id.equals(entryId)))
          .write(TimetableEntriesCompanion(
            venueId: Value(venueId),
          ));
}
