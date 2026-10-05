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
const kAutoResolveTask = 'auto_resolve_stale';

/// Background task scheduler — SPEC.md §5.4, §6.2, §9.
///
/// Uses WorkManager to schedule GPS checks ONLY during active class windows.
/// Check density follows the adaptive polling schedule from §6.2:
/// - HIGH density in first/last 15% of class (catches late arrivals / early leavers)
/// - LOW density in middle 70% (students stable mid-class)
/// - Check times randomized within each window (not predictable)
/// - Each check is a one-off WorkManager task (lightweight, not continuous polling)
///
/// Updated for attendance-rules.md:
/// - Skips scheduling on holidays (§4)
/// - Runs 48-hour auto-resolve job for stale ambiguous/unknown records (§5)
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
  ///
  /// Per attendance-rules.md §4: skips scheduling if today is a holiday.
  /// Extended for academic calendar:
  /// - Compensatory days: loads the alternate day's timetable
  /// - Half-days: only schedules morning or afternoon classes
  /// - Restricted holidays: tracks but marks classification as 'restricted'
  /// - Exams/vacations/holidays/cancelled: no tracking at all
  static Future<void> scheduleChecksForToday() async {
    final db = AppDatabase();

    try {
      final now = DateTime.now();
      var today = now.weekday; // 1=Monday, 7=Sunday (ISO 8601)

      // --- Check academic calendar for today ---
      final event = await db.holidaysDao.getEventForDate(now);

      if (event != null) {
        final eventType = event.eventType;

        // Full suppression types — no tracking at all
        if (eventType == 'holiday' ||
            eventType == 'exam' ||
            eventType == 'cancelled' ||
            eventType == 'vacation') {
          return;
        }

        // Compensatory day — use the alternate day's timetable
        if (eventType == 'compensatory' && event.followsDay != null) {
          today = _weekdayFromName(event.followsDay!);
        }
      }

      // Determine half-day constraints (null = full day)
      final halfDayType = await db.holidaysDao.getHalfDayType(now);

      // Get today's active timetable entries (or compensatory day's entries)
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

        // --- Half-day filtering ---
        // If half_day_morning: morning classes are OFF → skip classes before 12:00
        // If half_day_afternoon: afternoon classes are OFF → skip classes at/after 12:00
        if (halfDayType == 'morning' && startHour < 12) continue;
        if (halfDayType == 'afternoon' && startHour >= 12) continue;

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

      // --- Rule 5: Schedule auto-resolve for stale records ---
      await _autoResolveStaleRecords(db);
    } finally {
      await db.close();
    }
  }

  /// Convert a weekday name (e.g. "monday") to ISO 8601 weekday number.
  static int _weekdayFromName(String name) {
    const map = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };
    return map[name.toLowerCase()] ?? 1;
  }

  /// Auto-resolve stale ambiguous/unknown records per attendance-rules.md §5.
  ///
  /// Any record still ambiguous or unknown after 48 hours auto-resolves:
  /// - If partial signal exists → resolve toward what the data leans
  /// - If zero signal → resolve to 'absent' (conservative assumption)
  /// Marked with autoResolved=true so the UI shows them distinctly.
  static Future<void> _autoResolveStaleRecords(AppDatabase db) async {
    const staleThreshold = Duration(hours: 48);
    final staleRecords =
        await db.attendanceRecordsDao.getStaleUnresolvedRecords(staleThreshold);

    for (final record in staleRecords) {
      String resolvedStatus;

      // Check if there's any partial signal data
      if (record.checksJson != '[]' && record.checksJson.isNotEmpty) {
        // Partial data exists — lean toward what the confidence suggests
        if (record.confidenceScore >= 0.5) {
          resolvedStatus = 'present';
        } else {
          resolvedStatus = 'absent';
        }
      } else {
        // Zero signal (phone was off, no data at all) → absent by default
        resolvedStatus = 'absent';
      }

      await db.attendanceRecordsDao.autoResolve(record.id, resolvedStatus);
    }
  }

  /// Schedule a 9 PM notification summarizing tomorrow's classes.
  static Future<void> _scheduleNightBeforeSummary(
      AppDatabase db, DateTime now) async {
    // Tomorrow's weekday (ISO 8601: 1=Mon, 7=Sun)
    final tomorrowWeekday = now.weekday == 7 ? 1 : now.weekday + 1;

    // --- Rule 4: Check if tomorrow has a calendar event ---
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowEvent = await db.holidaysDao.getEventForDate(tomorrow);
    
    // Formatting the event for the notification
    String? eventLabel;
    bool suppressClasses = false;
    
    if (tomorrowEvent != null) {
      eventLabel = '${tomorrowEvent.label} (${tomorrowEvent.eventType})';
      
      const suppressTypes = {'holiday', 'exam', 'cancelled', 'vacation'};
      if (suppressTypes.contains(tomorrowEvent.eventType)) {
        suppressClasses = true;
      }
    }

    final classList = <Map<String, String>>[];
    
    // Only get classes if attendance isn't fully suppressed
    if (!suppressClasses) {
      // Handle compensatory day logic for tomorrow
      var effectiveWeekday = tomorrowWeekday;
      if (tomorrowEvent?.eventType == 'compensatory' && tomorrowEvent?.followsDay != null) {
        effectiveWeekday = _weekdayFromName(tomorrowEvent!.followsDay!);
      }
      
      final tomorrowEntries = await db.timetableEntriesDao.getEntriesForDay(effectiveWeekday);

      final halfDayType = await db.holidaysDao.getHalfDayType(tomorrow);

      for (final entry in tomorrowEntries) {
        // Filter based on half days
        final startHour = int.parse(entry.startTime.split(':')[0]);
        if (halfDayType == 'morning' && startHour < 12) continue;
        if (halfDayType == 'afternoon' && startHour >= 12) continue;

        final subject = await db.subjectsDao.getSubjectById(entry.subjectId);
        classList.add({
          'name': subject.name,
          'time': entry.startTime,
        });
      }
    }

    await NotificationService.scheduleNightBeforeSummary(
      tomorrowClasses: classList,
      calendarEvent: eventLabel,
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
                    AttendanceStatus.fromDbValue(record.attendanceStatus);
                if (status == AttendanceStatus.present ||
                    status == AttendanceStatus.absent) {
                  final subject = await db.subjectsDao
                      .getSubjectById(entry.subjectId);
                  await NotificationService.showAttendanceMarked(
                    subjectName: subject.name,
                    status: record.attendanceStatus,
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
