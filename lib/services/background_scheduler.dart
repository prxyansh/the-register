import 'package:workmanager/workmanager.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../data/app_database.dart';
import '../data/attendance_status.dart';
import '../domain/adaptive_schedule.dart';
import 'attendance_checker.dart';
import 'notification_service.dart';

/// Task names for WorkManager.
const kAttendanceCheckTask = 'attendance_check';
const kScheduleClassChecksTask = 'schedule_class_checks';

/// Background task scheduler — SPEC.md §5.4, §6.2, §9.
///
/// Uses WorkManager to schedule GPS checks ONLY during active class windows.
/// Check density follows the adaptive polling schedule from §6.2:
/// - HIGH density in first/last 15% of class (catches late arrivals / early leavers)
/// - LOW density in middle 70% (students stable mid-class)
/// - Check times randomized within each window (not predictable)
/// - Each check is a one-off WorkManager task (lightweight, not continuous polling)
class BackgroundScheduler {
  /// Initialize WorkManager and register the background task dispatcher.
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
  }

  /// Schedule the daily planner that runs periodically.
  /// This task will look at today's timetable and schedule check tasks.
  static Future<void> scheduleDailyPlanner() async {
    await Workmanager().registerPeriodicTask(
      'daily_class_planner',
      kScheduleClassChecksTask,
      frequency: const Duration(hours: 12),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  /// Cancel all scheduled background tasks.
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }

  /// Schedule adaptive checks for today's classes.
  /// Called when: app opens, timetable changes, or daily planner fires.
  static Future<void> scheduleChecksForToday() async {
    final db = AppDatabase();

    try {
      final now = DateTime.now();
      final today = now.weekday; // 1=Monday, 7=Sunday (ISO 8601)

      // Get today's active timetable entries
      final entries =
          await db.timetableEntriesDao.getEntriesForDay(today);

      for (final entry in entries) {
        // Only schedule for entries with a venue
        if (entry.venueId == null) continue;

        // Parse start and end times
        final startParts = entry.startTime.split(':');
        final endParts = entry.endTime.split(':');
        final startHour = int.parse(startParts[0]);
        final startMinute = int.parse(startParts[1]);
        final endHour = int.parse(endParts[0]);
        final endMinute = int.parse(endParts[1]);

        final classStart = DateTime(
            now.year, now.month, now.day, startHour, startMinute);
        final classEnd =
            DateTime(now.year, now.month, now.day, endHour, endMinute);

        // Skip classes that have already ended
        if (classEnd.isBefore(now)) continue;

        // Generate adaptive check schedule (§6.2)
        final checkTimes = generateAdaptiveSchedule(
          classStart: classStart,
          classEnd: classEnd,
        );

        // Schedule each check as a one-off WorkManager task
        for (int i = 0; i < checkTimes.length; i++) {
          final checkTime = checkTimes[i];

          // Only schedule future checks
          if (checkTime.isBefore(now)) continue;

          final delay = checkTime.difference(now);
          await Workmanager().registerOneOffTask(
            'check_${entry.id}_${now.day}_$i',
            kAttendanceCheckTask,
            initialDelay: delay,
            inputData: {'entryId': entry.id},
            constraints: Constraints(
              networkType: NetworkType.notRequired,
            ),
            existingWorkPolicy: ExistingWorkPolicy.keep,
          );
        }

        // If we're currently IN a class window, also do an immediate check
        if (now.isAfter(classStart) && now.isBefore(classEnd)) {
          await Workmanager().registerOneOffTask(
            'check_now_${entry.id}_${now.day}',
            kAttendanceCheckTask,
            initialDelay: Duration.zero,
            inputData: {'entryId': entry.id},
            constraints: Constraints(
              networkType: NetworkType.notRequired,
            ),
            existingWorkPolicy: ExistingWorkPolicy.keep,
          );
        }

        // --- Schedule class reminder notification (15 min before) ---
        final subject = await db.subjectsDao.getSubjectById(entry.subjectId);
        await NotificationService.scheduleClassReminder(
          entryId: entry.id,
          subjectName: subject.name,
          startTime: entry.startTime,
          classDateTime: classStart,
        );
      }

      // --- Schedule night-before summary for tomorrow ---
      await _scheduleNightBeforeSummary(db, now);
    } finally {
      await db.close();
    }
  }

  /// Schedule a 9 PM notification summarizing tomorrow's classes.
  static Future<void> _scheduleNightBeforeSummary(
      AppDatabase db, DateTime now) async {
    // Tomorrow's weekday (ISO 8601: 1=Mon, 7=Sun)
    final tomorrowWeekday = now.weekday == 7 ? 1 : now.weekday + 1;
    final tomorrowEntries =
        await db.timetableEntriesDao.getEntriesForDay(tomorrowWeekday);

    if (tomorrowEntries.isEmpty) return;

    final classList = <Map<String, String>>[];
    for (final entry in tomorrowEntries) {
      final subject =
          await db.subjectsDao.getSubjectById(entry.subjectId);
      classList.add({
        'name': subject.name,
        'time': entry.startTime,
      });
    }

    await NotificationService.scheduleNightBeforeSummary(
      tomorrowClasses: classList,
    );
  }
}

/// Top-level callback for WorkManager background tasks.
/// Must be a top-level function (not a closure or method).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // Create a fresh database connection for this isolate
    final db = AppDatabase(
      driftDatabase(name: 'attendance_tracker'),
    );

    try {
      switch (taskName) {
        case kScheduleClassChecksTask:
          // Re-schedule today's class checks
          await BackgroundScheduler.scheduleChecksForToday();
          break;

        case kAttendanceCheckTask:
          // Perform a multi-signal check for the given entry
          final entryId = inputData?['entryId'] as int?;
          if (entryId != null) {
            final entry =
                await db.timetableEntriesDao.getEntryById(entryId);
            final checker = AttendanceChecker(db);
            await checker.performCheck(entry);

            // Send attendance notification
            try {
              final today = DateTime.now();
              final startOfDay =
                  DateTime(today.year, today.month, today.day);
              final endOfDay = startOfDay.add(const Duration(days: 1));
              final records = await (db.select(db.attendanceRecords)
                    ..where((r) =>
                        r.timetableEntryId.equals(entry.id) &
                        r.date.isBiggerOrEqualValue(startOfDay) &
                        r.date.isSmallerThanValue(endOfDay)))
                  .get();
              if (records.isNotEmpty) {
                final record = records.first;
                final status =
                    AttendanceStatus.fromDbValue(record.status);
                if (status == AttendanceStatus.present ||
                    status == AttendanceStatus.absent) {
                  final subject = await db.subjectsDao
                      .getSubjectById(entry.subjectId);
                  await NotificationService.showAttendanceMarked(
                    subjectName: subject.name,
                    status: record.status,
                  );
                }
              }
            } catch (_) {
              // Non-critical — don't fail the check
            }
          }
          break;
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      await db.close();
    }
  });
}
