import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'holidays_dao.g.dart';

/// DAO for CRUD operations on the Holidays / Academic Calendar table.
/// Per attendance-rules.md §4: campus-wide closures that suppress
/// record generation and GPS checks for all subjects.
///
/// Extended for academic calendar import: supports event types,
/// date ranges (vacation/exam periods), compensatory days, and more.
@DriftAccessor(tables: [Holidays])
class HolidaysDao extends DatabaseAccessor<AppDatabase>
    with _$HolidaysDaoMixin {
  HolidaysDao(super.db);

  /// Get all holidays as a reactive stream, sorted by date.
  Stream<List<Holiday>> watchAllHolidays() =>
      (select(holidays)..orderBy([(h) => OrderingTerm.asc(h.date)])).watch();

  /// Get all holidays (one-shot).
  Future<List<Holiday>> getAllHolidays() =>
      (select(holidays)..orderBy([(h) => OrderingTerm.asc(h.date)])).get();

  /// Check if a specific date is a holiday (any type that suppresses attendance).
  /// This checks both single-day events AND date ranges.
  /// Returns true for: holiday, exam, cancelled, vacation.
  /// Returns false for: compensatory, restricted, half_day_*.
  Future<bool> isHoliday(DateTime date) async {
    final event = await getEventForDate(date);
    if (event == null) return false;
    // These event types fully suppress attendance tracking
    const suppressTypes = {'holiday', 'exam', 'cancelled', 'vacation'};
    return suppressTypes.contains(event.eventType);
  }

  /// Get the calendar event for a specific date, if any.
  /// Checks both exact single-day matches AND date ranges (endDate).
  Future<Holiday?> getEventForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // 1. Check single-day events (no endDate)
    final singleDay = await (select(holidays)
          ..where((h) =>
              h.date.isBiggerOrEqualValue(startOfDay) &
              h.date.isSmallerThanValue(endOfDay) &
              h.endDate.isNull()))
        .get();
    if (singleDay.isNotEmpty) return singleDay.first;

    // 2. Check range events (date <= target <= endDate)
    final rangeEvents = await (select(holidays)
          ..where((h) =>
              h.endDate.isNotNull() &
              h.date.isSmallerOrEqualValue(endOfDay) &
              h.endDate.isBiggerOrEqualValue(startOfDay)))
        .get();
    if (rangeEvents.isNotEmpty) return rangeEvents.first;

    return null;
  }

  /// Get the holiday entry for a specific date (legacy compatibility).
  Future<Holiday?> getHolidayForDate(DateTime date) => getEventForDate(date);

  /// Get holidays within a date range (for calendar view).
  Future<List<Holiday>> getHolidaysInRange(DateTime start, DateTime end) =>
      (select(holidays)
            ..where((h) =>
                // Single-day events in range
                (h.date.isBiggerOrEqualValue(start) &
                    h.date.isSmallerThanValue(end)) |
                // Range events that overlap with the query range
                (h.endDate.isNotNull() &
                    h.date.isSmallerThanValue(end) &
                    h.endDate.isBiggerOrEqualValue(start)))
            ..orderBy([(h) => OrderingTerm.asc(h.date)]))
          .get();

  /// Watch holidays within a date range (reactive, for calendar).
  Stream<List<Holiday>> watchHolidaysInRange(DateTime start, DateTime end) =>
      (select(holidays)
            ..where((h) =>
                (h.date.isBiggerOrEqualValue(start) &
                    h.date.isSmallerThanValue(end)) |
                (h.endDate.isNotNull() &
                    h.date.isSmallerThanValue(end) &
                    h.endDate.isBiggerOrEqualValue(start)))
            ..orderBy([(h) => OrderingTerm.asc(h.date)]))
          .watch();

  /// Get all events of a specific type.
  Future<List<Holiday>> getEventsByType(String eventType) =>
      (select(holidays)
            ..where((h) => h.eventType.equals(eventType))
            ..orderBy([(h) => OrderingTerm.asc(h.date)]))
          .get();

  /// Check if a date is a compensatory day and return which day's
  /// timetable to follow (e.g. "monday").
  Future<String?> getCompensatoryDay(DateTime date) async {
    final event = await getEventForDate(date);
    if (event == null || event.eventType != 'compensatory') return null;
    return event.followsDay;
  }

  /// Check if a date is a restricted holiday (optional attendance).
  Future<bool> isRestrictedHoliday(DateTime date) async {
    final event = await getEventForDate(date);
    return event?.eventType == 'restricted';
  }

  /// Check if a date is a half-day and return which half is off.
  /// Returns 'morning' if morning classes are cancelled (half_day_morning),
  /// 'afternoon' if afternoon classes are cancelled (half_day_afternoon),
  /// or null if not a half-day.
  Future<String?> getHalfDayType(DateTime date) async {
    final event = await getEventForDate(date);
    if (event == null) return null;
    if (event.eventType == 'half_day_morning') return 'morning';
    if (event.eventType == 'half_day_afternoon') return 'afternoon';
    return null;
  }

  /// Insert a new holiday, returns the generated ID.
  Future<int> insertHoliday(HolidaysCompanion holiday) =>
      into(holidays).insert(holiday);

  /// Bulk insert holidays (for academic calendar import).
  /// Returns count of inserted events.
  Future<int> bulkInsertHolidays(List<HolidaysCompanion> events) async {
    int count = 0;
    for (final event in events) {
      await into(holidays).insert(event);
      count++;
    }
    return count;
  }

  /// Update an existing holiday.
  Future<bool> updateHoliday(Holiday holiday) =>
      update(holidays).replace(holiday);

  /// Delete a holiday by ID.
  Future<int> deleteHolidayById(int id) =>
      (delete(holidays)..where((h) => h.id.equals(id))).go();

  /// Delete any events that overlap with a specific date range.
  Future<int> deleteEventsInRange(DateTime start, DateTime end) {
    return (delete(holidays)
          ..where((h) =>
              (h.date.isBiggerOrEqualValue(start) &
                  h.date.isSmallerOrEqualValue(end)) |
              (h.endDate.isNotNull() &
                  h.date.isSmallerOrEqualValue(end) &
                  h.endDate.isBiggerOrEqualValue(start))))
        .go();
  }

  /// Delete all holidays (for reimport).
  Future<int> deleteAll() => delete(holidays).go();

  /// Get total event counts by type (for stats display).
  Future<Map<String, int>> getEventCountsByType() async {
    final all = await getAllHolidays();
    final counts = <String, int>{};
    for (final h in all) {
      counts[h.eventType] = (counts[h.eventType] ?? 0) + 1;
    }
    return counts;
  }
}
