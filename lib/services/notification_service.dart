import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Notification service for class reminders and attendance confirmations.
///
/// Handles:
/// - Class reminder 15 min before start
/// - Night-before summary of tomorrow's classes (9 PM)
/// - Attendance marked confirmation
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Channel IDs
  static const String _classReminderChannelId = 'class_reminders';
  static const String _attendanceChannelId = 'attendance_updates';
  static const String _nightBeforeChannelId = 'night_before_summary';

  /// Initialize the notification plugin.
  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: initSettings);

    // Create notification channels
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _classReminderChannelId,
          'Class Reminders',
          description: 'Notifications before your classes start',
          importance: Importance.high,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _attendanceChannelId,
          'Attendance Updates',
          description: 'Notifications when attendance is marked',
          importance: Importance.defaultImportance,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _nightBeforeChannelId,
          'Tomorrow\'s Schedule',
          description: 'Summary of next day\'s classes the night before',
          importance: Importance.defaultImportance,
        ),
      );

      // Request notification permission on Android 13+
      await androidPlugin.requestNotificationsPermission();
    }

    _initialized = true;
  }

  /// Schedule a "class starts in 15 min" notification.
  static Future<void> scheduleClassReminder({
    required int entryId,
    required String subjectName,
    required String startTime,
    required DateTime classDateTime,
  }) async {
    await initialize();

    final reminderTime =
        classDateTime.subtract(const Duration(minutes: 15));
    final now = DateTime.now();

    // Don't schedule if the reminder time has already passed
    if (reminderTime.isBefore(now)) return;

    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

    await _plugin.zonedSchedule(
      id: entryId * 100, // Unique ID per entry
      title: 'Upcoming Class',
      body: '$subjectName starts at $startTime',
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _classReminderChannelId,
          'Class Reminders',
          channelDescription: 'Notifications before your classes start',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Schedule a night-before summary notification at 9 PM.
  static Future<void> scheduleNightBeforeSummary({
    required List<Map<String, String>> tomorrowClasses,
  }) async {
    await initialize();

    if (tomorrowClasses.isEmpty) return;

    final now = DateTime.now();
    var ninepm = DateTime(now.year, now.month, now.day, 21, 0);

    // If it's already past 9 PM, don't schedule
    if (ninepm.isBefore(now)) return;

    final classListText = tomorrowClasses
        .map((c) => '${c['name']} (${c['time']})')
        .join(', ');

    final body = tomorrowClasses.length == 1
        ? 'You have 1 class tomorrow: $classListText'
        : 'You have ${tomorrowClasses.length} classes tomorrow: $classListText';

    final scheduledDate = tz.TZDateTime.from(ninepm, tz.local);

    await _plugin.zonedSchedule(
      id: 99999, // Fixed ID for night-before summary
      title: 'Tomorrow\'s Classes',
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _nightBeforeChannelId,
          'Tomorrow\'s Schedule',
          channelDescription:
              'Summary of next day\'s classes the night before',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Show an immediate notification when attendance is marked.
  static Future<void> showAttendanceMarked({
    required String subjectName,
    required String status,
  }) async {
    await initialize();

    final isPresent = status == 'present';
    final icon = isPresent ? '✓' : '✗';
    final title =
        isPresent ? '$icon Marked Present' : '$icon Marked Absent';

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: subjectName,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _attendanceChannelId,
          'Attendance Updates',
          channelDescription: 'Notifications when attendance is marked',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Cancel all scheduled notifications.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
