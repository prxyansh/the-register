import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/app_database.dart';

/// Export & import service — SPEC.md §7.
///
/// - JSON export: serializes all tables (including Holidays) to a single JSON file.
/// - CSV export: human-readable CSV of AttendanceRecords with new fields.
/// - JSON import: restores data with merge/overwrite support.
///
/// Updated for attendance-rules.md: exports/imports the two-field model
/// (attendanceStatus + classification), autoResolved flag, and Holidays table.
class BackupService {
  final AppDatabase db;

  BackupService(this.db);

  /// Export all data as a JSON file and share it.
  /// Returns the path to the exported file.
  Future<String> exportJson() async {
    final subjects = await db.subjectsDao.getAllSubjects();
    final venues = await db.venuesDao.getAllVenues();
    final entries = await db.timetableEntriesDao.getAllEntries();
    final records = await db.attendanceRecordsDao.getAllRecords();
    final holidays = await db.holidaysDao.getAllHolidays();

    final data = {
      'version': 2, // Bumped for new schema
      'exported_at': DateTime.now().toIso8601String(),
      'app': 'attendance_tracker',
      'subjects': subjects
          .map((s) => {
                'id': s.id,
                'name': s.name,
                'color': s.color,
                'target_attendance_pct': s.targetAttendancePct,
                'faculty_name': s.facultyName,
              })
          .toList(),
      'venues': venues
          .map((v) => {
                'id': v.id,
                'name': v.name,
                'latitude': v.latitude,
                'longitude': v.longitude,
                'radius_meters': v.radiusMeters,
                'wifi_ssid': v.wifiSsid,
              })
          .toList(),
      'timetable_entries': entries
          .map((e) => {
                'id': e.id,
                'subject_id': e.subjectId,
                'day_of_week': e.dayOfWeek,
                'start_time': e.startTime,
                'end_time': e.endTime,
                'venue_id': e.venueId,
                'active': e.active,
              })
          .toList(),
      'attendance_records': records
          .map((r) => {
                'id': r.id,
                'timetable_entry_id': r.timetableEntryId,
                'date': r.date.toIso8601String(),
                'attendance_status': r.attendanceStatus,
                'classification': r.classification,
                'confidence_score': r.confidenceScore,
                'checks_json': r.checksJson,
                'override_reason': r.overrideReason,
                'auto_resolved': r.autoResolved,
              })
          .toList(),
      'holidays': holidays
          .map((h) => {
                'id': h.id,
                'date': h.date.toIso8601String(),
                'label': h.label,
              })
          .toList(),
    };

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/attendance_backup_$timestamp.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
    );

    return file.path;
  }

  /// Export attendance records as CSV and share.
  /// Returns the path to the exported file.
  Future<String> exportCsv() async {
    final records = await db.attendanceRecordsDao.getAllRecords();
    final entries = await db.timetableEntriesDao.getAllEntries();
    final subjects = await db.subjectsDao.getAllSubjects();

    final buffer = StringBuffer();
    buffer.writeln('Date,Day,Subject,Start Time,End Time,Status,Classification,Confidence,Override Reason,Auto Resolved');

    for (final record in records) {
      final entry = entries.cast<TimetableEntry?>().firstWhere(
            (e) => e!.id == record.timetableEntryId,
            orElse: () => null,
          );
      final subject = entry != null
          ? subjects.cast<Subject?>().firstWhere(
                (s) => s!.id == entry.subjectId,
                orElse: () => null,
              )
          : null;

      final dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      buffer.writeln([
        DateFormat('yyyy-MM-dd').format(record.date),
        entry != null ? dayNames[entry.dayOfWeek] : '',
        _csvEscape(subject?.name ?? 'Unknown'),
        entry?.startTime ?? '',
        entry?.endTime ?? '',
        record.attendanceStatus,
        record.classification,
        record.confidenceScore.toStringAsFixed(2),
        _csvEscape(record.overrideReason ?? ''),
        record.autoResolved ? 'Yes' : 'No',
      ].join(','));
    }

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/attendance_$timestamp.csv');
    await file.writeAsString(buffer.toString());

    return file.path;
  }

  /// Share the exported file via the system share sheet.
  Future<void> shareFile(String path) async {
    await Share.shareXFiles([XFile(path)]);
  }

  /// List available backup files in the app documents directory.
  /// Returns files sorted by modification date (newest first).
  static Future<List<File>> listBackupFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json') && f.path.contains('attendance_backup'))
        .toList();
    // Sort newest first
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  /// Import data from a JSON backup file.
  /// Returns a summary of what was imported.
  ///
  /// Handles both v1 (old single-status model) and v2 (new two-field model) formats.
  Future<ImportResult> importJson(String jsonContent) async {
    final data = jsonDecode(jsonContent) as Map<String, dynamic>;

    // Validate format
    if (data['app'] != 'attendance_tracker') {
      throw FormatException('Not a valid attendance tracker backup file.');
    }

    final backupVersion = data['version'] as int? ?? 1;

    int subjectsImported = 0;
    int venuesImported = 0;
    int entriesImported = 0;
    int recordsImported = 0;
    int holidaysImported = 0;

    // Import subjects
    final subjectsData = data['subjects'] as List<dynamic>? ?? [];
    for (final s in subjectsData) {
      final map = s as Map<String, dynamic>;
      try {
        await db.subjectsDao.insertSubject(SubjectsCompanion.insert(
          name: map['name'] as String,
          color: map['color'] as int,
          targetAttendancePct: Value((map['target_attendance_pct'] as num).toDouble()),
          facultyName: Value(map['faculty_name'] as String?),
        ));
        subjectsImported++;
      } catch (_) {
        // Skip duplicates or conflicts
      }
    }

    // Import venues
    final venuesData = data['venues'] as List<dynamic>? ?? [];
    for (final v in venuesData) {
      final map = v as Map<String, dynamic>;
      try {
        await db.venuesDao.insertVenue(VenuesCompanion.insert(
          name: map['name'] as String,
          latitude: (map['latitude'] as num).toDouble(),
          longitude: (map['longitude'] as num).toDouble(),
          radiusMeters: Value((map['radius_meters'] as num).toDouble()),
          wifiSsid: Value(map['wifi_ssid'] as String?),
        ));
        venuesImported++;
      } catch (_) {}
    }

    // Import timetable entries
    final entriesData = data['timetable_entries'] as List<dynamic>? ?? [];
    for (final e in entriesData) {
      final map = e as Map<String, dynamic>;
      try {
        await db.timetableEntriesDao.insertEntry(TimetableEntriesCompanion.insert(
          subjectId: map['subject_id'] as int,
          dayOfWeek: map['day_of_week'] as int,
          startTime: map['start_time'] as String,
          endTime: map['end_time'] as String,
          venueId: Value(map['venue_id'] as int?),
          active: Value(map['active'] as bool? ?? true),
        ));
        entriesImported++;
      } catch (_) {}
    }

    // Import attendance records — handle both v1 and v2 formats
    final recordsData = data['attendance_records'] as List<dynamic>? ?? [];
    for (final r in recordsData) {
      final map = r as Map<String, dynamic>;
      try {
        String attendanceStatus;
        String classification;
        bool autoResolved;

        if (backupVersion >= 2) {
          // v2 format: has the new fields directly
          attendanceStatus = map['attendance_status'] as String? ?? 'unknown';
          classification = map['classification'] as String? ?? 'normal';
          autoResolved = map['auto_resolved'] as bool? ?? false;
        } else {
          // v1 format: migrate old 'status' field
          final oldStatus = map['status'] as String? ?? 'unknown';
          if (oldStatus == 'manual_override') {
            attendanceStatus = map['override_reason'] != null ? 'absent' : 'present';
            classification = map['override_reason'] != null ? 'excused' : 'normal';
          } else {
            attendanceStatus = oldStatus;
            classification = 'normal';
          }
          autoResolved = false;
        }

        await db.attendanceRecordsDao.insertRecord(AttendanceRecordsCompanion.insert(
          timetableEntryId: map['timetable_entry_id'] as int,
          date: DateTime.parse(map['date'] as String),
          attendanceStatus: Value(attendanceStatus),
          classification: Value(classification),
          confidenceScore: Value((map['confidence_score'] as num?)?.toDouble() ?? 0.0),
          checksJson: Value(map['checks_json'] as String? ?? '[]'),
          overrideReason: Value(map['override_reason'] as String?),
          autoResolved: Value(autoResolved),
        ));
        recordsImported++;
      } catch (_) {}
    }

    // Import holidays (v2 only)
    if (backupVersion >= 2) {
      final holidaysData = data['holidays'] as List<dynamic>? ?? [];
      for (final h in holidaysData) {
        final map = h as Map<String, dynamic>;
        try {
          await db.holidaysDao.insertHoliday(HolidaysCompanion.insert(
            date: DateTime.parse(map['date'] as String),
            label: Value(map['label'] as String? ?? 'Holiday'),
          ));
          holidaysImported++;
        } catch (_) {}
      }
    }

    return ImportResult(
      subjectsImported: subjectsImported,
      venuesImported: venuesImported,
      entriesImported: entriesImported,
      recordsImported: recordsImported,
      holidaysImported: holidaysImported,
    );
  }

  /// Escape a string for CSV output.
  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

/// Result of an import operation.
class ImportResult {
  final int subjectsImported;
  final int venuesImported;
  final int entriesImported;
  final int recordsImported;
  final int holidaysImported;

  ImportResult({
    required this.subjectsImported,
    required this.venuesImported,
    required this.entriesImported,
    required this.recordsImported,
    this.holidaysImported = 0,
  });

  int get totalImported =>
      subjectsImported + venuesImported + entriesImported + recordsImported + holidaysImported;

  @override
  String toString() =>
      '$subjectsImported subjects, $venuesImported venues, '
      '$entriesImported entries, $recordsImported records, '
      '$holidaysImported holidays';
}
