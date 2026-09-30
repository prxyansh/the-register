import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:attendance_tracker/data/app_database.dart';

/// Schema test — verifies all four tables from SPEC.md §4 work correctly.
/// Inserts and reads back one row from each table.
void main() {
  late AppDatabase db;

  setUp(() {
    // Use an in-memory database for testing
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Insert and read a Subject', () async {
    final id = await db.subjectsDao.insertSubject(
      SubjectsCompanion.insert(
        name: 'Data Structures',
        color: 0xFF4CAF50,
        targetAttendancePct: const Value(75.0),
      ),
    );

    final subject = await db.subjectsDao.getSubjectById(id);
    expect(subject.name, 'Data Structures');
    expect(subject.color, 0xFF4CAF50);
    expect(subject.targetAttendancePct, 75.0);
  });

  test('Insert and read a Venue', () async {
    final id = await db.venuesDao.insertVenue(
      VenuesCompanion.insert(
        name: 'Main Hall - CS101',
        latitude: 10.7620,
        longitude: 79.4980,
        radiusMeters: const Value(30.0),
        wifiSsid: const Value('NITT-WiFi'),
      ),
    );

    final venue = await db.venuesDao.getVenueById(id);
    expect(venue.name, 'Main Hall - CS101');
    expect(venue.latitude, 10.7620);
    expect(venue.longitude, 79.4980);
    expect(venue.radiusMeters, 30.0);
    expect(venue.wifiSsid, 'NITT-WiFi');
  });

  test('Insert and read a TimetableEntry', () async {
    // First insert a subject (foreign key requirement)
    final subjectId = await db.subjectsDao.insertSubject(
      SubjectsCompanion.insert(
        name: 'Algorithms',
        color: 0xFF2196F3,
      ),
    );

    final entryId = await db.timetableEntriesDao.insertEntry(
      TimetableEntriesCompanion.insert(
        subjectId: subjectId,
        dayOfWeek: 1, // Monday
        startTime: '09:00',
        endTime: '10:00',
      ),
    );

    final entry = await db.timetableEntriesDao.getEntryById(entryId);
    expect(entry.subjectId, subjectId);
    expect(entry.dayOfWeek, 1);
    expect(entry.startTime, '09:00');
    expect(entry.endTime, '10:00');
    expect(entry.active, true); // Default value
    expect(entry.venueId, isNull); // Nullable for Task 2
  });

  test('Insert and read an AttendanceRecord', () async {
    // Insert subject and timetable entry first (foreign key chain)
    final subjectId = await db.subjectsDao.insertSubject(
      SubjectsCompanion.insert(
        name: 'Operating Systems',
        color: 0xFFFF5722,
      ),
    );

    final entryId = await db.timetableEntriesDao.insertEntry(
      TimetableEntriesCompanion.insert(
        subjectId: subjectId,
        dayOfWeek: 3, // Wednesday
        startTime: '14:00',
        endTime: '15:00',
      ),
    );

    final now = DateTime.now();
    final recordId = await db.attendanceRecordsDao.insertRecord(
      AttendanceRecordsCompanion.insert(
        timetableEntryId: entryId,
        date: now,
        status: 'present',
        confidenceScore: const Value(0.92),
        checksJson: const Value('[{"time":"14:05","gps":true,"wifi":true}]'),
      ),
    );

    final record = await db.attendanceRecordsDao.getRecordById(recordId);
    expect(record.timetableEntryId, entryId);
    expect(record.status, 'present');
    expect(record.confidenceScore, 0.92);
    expect(record.checksJson, contains('14:05'));
    expect(record.overrideReason, isNull);
  });

  test('Manual override updates status and reason', () async {
    // Set up the chain
    final subjectId = await db.subjectsDao.insertSubject(
      SubjectsCompanion.insert(
        name: 'Networks',
        color: 0xFF9C27B0,
      ),
    );

    final entryId = await db.timetableEntriesDao.insertEntry(
      TimetableEntriesCompanion.insert(
        subjectId: subjectId,
        dayOfWeek: 5, // Friday
        startTime: '11:00',
        endTime: '12:00',
      ),
    );

    final recordId = await db.attendanceRecordsDao.insertRecord(
      AttendanceRecordsCompanion.insert(
        timetableEntryId: entryId,
        date: DateTime.now(),
        status: 'absent',
        confidenceScore: const Value(0.15),
      ),
    );

    // Override to manual_override with reason
    await db.attendanceRecordsDao.overrideRecord(
      recordId,
      'manual_override',
      'Class was cancelled by professor',
    );

    final updated = await db.attendanceRecordsDao.getRecordById(recordId);
    expect(updated.status, 'manual_override');
    expect(updated.overrideReason, 'Class was cancelled by professor');
  });
}
