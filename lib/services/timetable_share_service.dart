import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_selector/file_selector.dart';
import '../data/app_database.dart';

class TimetableShareService {
  final AppDatabase db;
  TimetableShareService(this.db);

  Future<String> generateShareCode() async {
    final subjects = await db.subjectsDao.getAllSubjects();
    final entries = await db.timetableEntriesDao.getAllEntries();
    
    final data = {
      'type': 'timetable_share',
      'version': 1,
      'subjects': subjects.map((s) => {
        'id': s.id,
        'name': s.name,
        'color': s.color,
        'target_attendance_pct': s.targetAttendancePct,
        if (s.facultyName != null) 'faculty_name': s.facultyName,
      }).toList(),
      'entries': entries.map((e) => {
        'subject_id': e.subjectId,
        'day_of_week': e.dayOfWeek,
        'start_time': e.startTime,
        'end_time': e.endTime,
      }).toList(),
    };
    
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    return base64Encode(bytes);
  }

  Future<String> exportJsonFile() async {
    final base64Code = await generateShareCode();
    final bytes = base64Decode(base64Code);
    final jsonString = utf8.decode(bytes);
    
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/timetable_share.json');
    await file.writeAsString(jsonString);
    
    return file.path;
  }

  Future<void> shareJsonFile() async {
    final path = await exportJsonFile();
    await Share.shareXFiles([XFile(path)], subject: 'Timetable Backup');
  }

  Future<int> importFromCode(String base64Code, {bool clearExisting = false}) async {
    try {
      final bytes = base64Decode(base64Code);
      final jsonString = utf8.decode(bytes);
      return await _importJson(jsonString, clearExisting: clearExisting);
    } catch (e) {
      throw FormatException('Invalid share code format.');
    }
  }

  Future<int> importFromJsonFile({bool clearExisting = false}) async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'json',
      extensions: <String>['json'],
    );
    final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    
    if (file != null) {
      final jsonString = await file.readAsString();
      return await _importJson(jsonString, clearExisting: clearExisting);
    }
    return 0; // Cancelled
  }

  Future<int> _importJson(String jsonContent, {bool clearExisting = false}) async {
    final data = jsonDecode(jsonContent) as Map<String, dynamic>;
    if (data['type'] != 'timetable_share') {
      throw FormatException('Not a valid timetable share file.');
    }
    
    if (clearExisting) {
      // Clear attendance records first to avoid foreign key issues
      await db.delete(db.attendanceRecords).go();
      await db.delete(db.timetableEntries).go();
      await db.delete(db.subjects).go();
    }
    
    final existingSubjects = await db.subjectsDao.getAllSubjects();
    final existingEntries = await db.timetableEntriesDao.getAllEntries();
    
    final subjectIdMap = <int, int>{};
    
    final subjectsData = data['subjects'] as List<dynamic>? ?? [];
    for (final s in subjectsData) {
      final map = s as Map<String, dynamic>;
      final oldId = map['id'] as int;
      final name = map['name'] as String;
      
      final existing = existingSubjects.cast<Subject?>().firstWhere(
        (sub) => sub!.name.toLowerCase() == name.toLowerCase(),
        orElse: () => null,
      );
      
      if (existing != null) {
        subjectIdMap[oldId] = existing.id;
      } else {
        final newId = await db.subjectsDao.insertSubject(SubjectsCompanion.insert(
          name: name,
          color: map['color'] as int,
          targetAttendancePct: Value((map['target_attendance_pct'] as num).toDouble()),
          facultyName: Value(map['faculty_name'] as String?),
        ));
        subjectIdMap[oldId] = newId;
      }
    }
    
    int importedCount = 0;
    final entriesData = data['entries'] as List<dynamic>? ?? [];
    for (final e in entriesData) {
      final map = e as Map<String, dynamic>;
      final oldSubjectId = map['subject_id'] as int;
      final newSubjectId = subjectIdMap[oldSubjectId];
      
      if (newSubjectId == null) continue;
      
      final dayOfWeek = map['day_of_week'] as int;
      final startTime = map['start_time'] as String;
      final endTime = map['end_time'] as String;
      
      final isDuplicate = existingEntries.any((entry) => 
        entry.subjectId == newSubjectId &&
        entry.dayOfWeek == dayOfWeek &&
        entry.startTime == startTime &&
        entry.endTime == endTime
      );
      
      if (!isDuplicate) {
        await db.timetableEntriesDao.insertEntry(TimetableEntriesCompanion.insert(
          subjectId: newSubjectId,
          dayOfWeek: dayOfWeek,
          startTime: startTime,
          endTime: endTime,
        ));
        importedCount++;
      }
    }
    
    return importedCount;
  }
}
