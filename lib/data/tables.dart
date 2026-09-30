import 'package:drift/drift.dart';

/// Subjects table — SPEC.md §4
/// Stores subject metadata (name, color for UI, target attendance percentage).
class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get color => integer()(); // Color value stored as int (e.g. 0xFF4CAF50)
  RealColumn get targetAttendancePct =>
      real().withDefault(const Constant(75.0))(); // Default 75%
}

/// Venues table — SPEC.md §4
/// Stores physical locations where classes are held, with GPS coordinates
/// and an optional WiFi SSID for secondary signal matching.
class Venues extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name =>
      text().withLength(min: 1, max: 200)(); // e.g. "Main Hall - CS101"
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get radiusMeters =>
      real().withDefault(const Constant(30.0))(); // Per-venue, not global
  TextColumn get wifiSsid =>
      text().nullable()(); // Optional secondary signal
}

/// TimetableEntries table — SPEC.md §4
/// Links a subject to a venue at a specific day/time slot.
class TimetableEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId =>
      integer().references(Subjects, #id)();
  IntColumn get venueId =>
      integer().nullable().references(Venues, #id)(); // Nullable for Task 2
  IntColumn get dayOfWeek =>
      integer()(); // 1=Monday, 7=Sunday (ISO 8601)
  TextColumn get startTime => text()(); // Stored as "HH:mm" string
  TextColumn get endTime => text()(); // Stored as "HH:mm" string
  BoolColumn get active =>
      boolean().withDefault(const Constant(true))(); // For exceptions/holidays
}

/// AttendanceRecords table — SPEC.md §4
/// One record per class occurrence per day. Stores detection results,
/// confidence score, raw check data, and optional manual override reason.
class AttendanceRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get timetableEntryId =>
      integer().references(TimetableEntries, #id)();
  DateTimeColumn get date => dateTime()(); // The date of the class occurrence
  TextColumn get status =>
      text()(); // Stored as string, mapped via AttendanceStatus enum
  RealColumn get confidenceScore =>
      real().withDefault(const Constant(0.0))(); // 0.0–1.0
  TextColumn get checksJson =>
      text().withDefault(const Constant('[]'))(); // Raw log of sample checks
  TextColumn get overrideReason =>
      text().nullable()(); // sick, cancelled, official leave, etc.
}
