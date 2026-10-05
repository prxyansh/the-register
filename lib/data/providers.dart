import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_database.dart';
import 'attendance_status.dart';
import 'daos/subjects_dao.dart';
import 'daos/venues_dao.dart';
import 'daos/timetable_entries_dao.dart';
import 'daos/attendance_records_dao.dart';
import 'daos/holidays_dao.dart';

/// Single database instance shared across the app.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// DAO providers — access these from widgets to interact with tables.
final subjectsDaoProvider = Provider<SubjectsDao>((ref) {
  return ref.watch(databaseProvider).subjectsDao;
});

final venuesDaoProvider = Provider<VenuesDao>((ref) {
  return ref.watch(databaseProvider).venuesDao;
});

final timetableEntriesDaoProvider = Provider<TimetableEntriesDao>((ref) {
  return ref.watch(databaseProvider).timetableEntriesDao;
});

final attendanceRecordsDaoProvider = Provider<AttendanceRecordsDao>((ref) {
  return ref.watch(databaseProvider).attendanceRecordsDao;
});

/// Holidays DAO provider — attendance-rules.md §4.
final holidaysDaoProvider = Provider<HolidaysDao>((ref) {
  return ref.watch(databaseProvider).holidaysDao;
});

/// Reactive stream providers for UI auto-updates.
final allSubjectsProvider = StreamProvider<List<Subject>>((ref) {
  return ref.watch(subjectsDaoProvider).watchAllSubjects();
});

final allTimetableEntriesProvider = StreamProvider<List<TimetableEntry>>((ref) {
  return ref.watch(timetableEntriesDaoProvider).watchAllEntries();
});

/// Reactive stream of all venues.
final allVenuesProvider = StreamProvider<List<Venue>>((ref) {
  return ref.watch(venuesDaoProvider).watchAllVenues();
});

/// Reactive stream of today's timetable entries (filtered by current weekday).
final todayEntriesProvider = StreamProvider<List<TimetableEntry>>((ref) {
  final today = DateTime.now().weekday; // 1=Mon, 7=Sun
  return ref.watch(timetableEntriesDaoProvider).watchEntriesForDay(today);
});

/// Reactive stream of today's attendance records.
final todayRecordsProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  return ref.watch(attendanceRecordsDaoProvider).watchRecordsForDate(DateTime.now());
});

/// Reactive stream of ALL attendance records (for reports).
final allRecordsProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  return ref.watch(attendanceRecordsDaoProvider).watchAllRecords();
});

/// Reactive stream of attendance records for a specific month (for Calendar).
final recordsForMonthProvider = StreamProvider.family<List<AttendanceRecord>, DateTime>((ref, month) {
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 1);
  return ref.watch(attendanceRecordsDaoProvider).watchRecordsForDateRange(start, end);
});

/// Reactive stream of all holidays — attendance-rules.md §4.
final allHolidaysProvider = StreamProvider<List<Holiday>>((ref) {
  return ref.watch(holidaysDaoProvider).watchAllHolidays();
});

/// Holidays for a specific month (for calendar display).
final holidaysForMonthProvider = StreamProvider.family<List<Holiday>, DateTime>((ref, month) {
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 1);
  return ref.watch(holidaysDaoProvider).watchHolidaysInRange(start, end);
});

/// User preference: how excused absences count — attendance-rules.md §6.
/// Default: excluded (Option A).
final excusedCountsAsProvider = StateProvider<ExcusedCountsAs>((ref) {
  return ExcusedCountsAs.excluded;
});

/// Load excused_counts_as setting from SharedPreferences.
final excusedCountsAsSettingProvider = FutureProvider<ExcusedCountsAs>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getString('excused_counts_as') ?? 'excluded';
  return ExcusedCountsAs.fromDbValue(value);
});
