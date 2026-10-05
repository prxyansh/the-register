import 'package:drift/drift.dart';

/// Subjects table — SPEC.md §4
/// Stores subject metadata (name, color for UI, target attendance percentage).
class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get color => integer()(); // Color value stored as int (e.g. 0xFF4CAF50)
  RealColumn get targetAttendancePct =>
      real().withDefault(const Constant(75.0))(); // Default 75%
  TextColumn get facultyName => text().nullable()(); // Optional faculty name
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

/// AttendanceRecords table — attendance-rules.md §1.
///
/// One record per class occurrence per day. Two-field model:
/// - `attendanceStatus`: what the detection engine observed (present/absent/ambiguous/unknown)
/// - `classification`: whether/how this record counts toward % (normal/cancelled/holiday/excused/extra_session)
///
/// Master rule (§2): A record counts toward % only if
/// classification is normal or extra_session, AND status is present or absent.
class AttendanceRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get timetableEntryId =>
      integer().references(TimetableEntries, #id)();
  DateTimeColumn get date => dateTime()(); // The date of the class occurrence

  /// What happened — detection result or manual entry.
  /// Values: present | absent | ambiguous | unknown
  TextColumn get attendanceStatus =>
      text().withDefault(const Constant('unknown'))();

  /// Whether/how this record counts toward attendance %.
  /// Values: normal | cancelled | holiday | excused | extra_session
  TextColumn get classification =>
      text().withDefault(const Constant('normal'))();

  RealColumn get confidenceScore =>
      real().withDefault(const Constant(0.0))(); // 0.0–1.0
  TextColumn get checksJson =>
      text().withDefault(const Constant('[]'))(); // Raw log of sample checks
  TextColumn get overrideReason =>
      text().nullable()(); // sick, cancelled, official leave, etc.

  /// Whether this record was auto-resolved from ambiguous/unknown
  /// after the 48-hour timeout (§5). Visually distinct in UI.
  BoolColumn get autoResolved =>
      boolean().withDefault(const Constant(false))();
}

/// Holidays / Academic Calendar table — attendance-rules.md §4.
///
/// Stores all academic calendar events: holidays, exams, vacations,
/// compensatory days, cancelled classes, and restricted holidays.
///
/// Event types and their effect on attendance:
/// - holiday:              Full day off. No tracking, no records.
/// - exam:                 Exam period. Regular classes paused, no attendance penalty.
/// - cancelled:            Classes cancelled (fest, event). No tracking.
/// - vacation:             Multi-day break (use endDate for range). No tracking.
/// - compensatory:         Working day on an off-day, follows another day's timetable.
///                         Uses followsDay (e.g. "monday") to load correct schedule.
/// - restricted:           Optional holiday. Tracking runs but won't penalize absence.
/// - half_day_morning:     Only afternoon classes run.
/// - half_day_afternoon:   Only morning classes run.
class Holidays extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()(); // Start date of the event
  DateTimeColumn get endDate => dateTime().nullable()(); // End date for multi-day events (vacation, exam)
  TextColumn get label =>
      text().withDefault(const Constant('Holiday'))(); // e.g. "Diwali", "Semester Break"
  /// Event type classification. Determines how the app handles attendance.
  /// Values: holiday | exam | cancelled | vacation | compensatory | restricted | half_day_morning | half_day_afternoon
  TextColumn get eventType =>
      text().withDefault(const Constant('holiday'))();
  /// For compensatory days: which day's timetable to follow.
  /// Values: monday | tuesday | wednesday | thursday | friday | saturday | sunday
  TextColumn get followsDay => text().nullable()();
}
