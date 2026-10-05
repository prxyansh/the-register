import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:file_selector/file_selector.dart';
import '../data/app_database.dart';

/// Service for importing academic calendar JSON files.
///
/// Parses the standardized JSON format that users generate via
/// ChatGPT/Gemini from their college's academic calendar (image/PDF/text).
///
/// JSON schema:
/// ```json
/// {
///   "type": "academic_calendar",
///   "institution": "NIT Trichy",
///   "semester": "Fall 2026",
///   "events": [
///     {
///       "date": "2026-10-24",
///       "end_date": null,        // optional, for multi-day events
///       "name": "Diwali",
///       "type": "holiday",       // holiday|exam|cancelled|vacation|compensatory|restricted|half_day_morning|half_day_afternoon
///       "follows_day": null      // only for compensatory type (e.g. "monday")
///     }
///   ]
/// }
/// ```
class CalendarImportService {
  final AppDatabase db;
  CalendarImportService(this.db);

  static const validEventTypes = {
    'holiday',
    'exam',
    'cancelled',
    'vacation',
    'compensatory',
    'restricted',
    'half_day_morning',
    'half_day_afternoon',
  };

  static const validWeekdays = {
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  };

  /// Import from a JSON file picked by the user.
  /// Returns the count of imported events.
  Future<int> importFromJsonFile({bool clearExisting = false}) async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'json',
      extensions: <String>['json'],
    );
    final XFile? file =
        await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

    if (file != null) {
      final jsonString = await file.readAsString();
      return await _importJson(jsonString, clearExisting: clearExisting);
    }
    return 0; // Cancelled
  }

  /// Import from a raw JSON string (for paste-based import).
  Future<int> importFromString(String jsonString,
      {bool clearExisting = false}) {
    return _importJson(jsonString, clearExisting: clearExisting);
  }

  /// Core import logic. Parses, validates, and writes to database.
  Future<int> _importJson(String jsonContent,
      {bool clearExisting = false}) async {
    final data = jsonDecode(jsonContent) as Map<String, dynamic>;

    // Validate file type
    if (data['type'] != 'academic_calendar') {
      throw const FormatException(
          'Not a valid academic calendar file. Expected "type": "academic_calendar".');
    }

    // Clear existing calendar if requested
    if (clearExisting) {
      await db.holidaysDao.deleteAll();
    }

    final events = data['events'] as List<dynamic>? ?? [];
    if (events.isEmpty) {
      throw const FormatException(
          'No events found in the calendar file.');
    }

    final companions = <HolidaysCompanion>[];

    for (int i = 0; i < events.length; i++) {
      final event = events[i] as Map<String, dynamic>;

      // Parse required date
      final dateStr = event['date'] as String?;
      if (dateStr == null || dateStr.isEmpty) {
        throw FormatException('Event #${i + 1} is missing a "date" field.');
      }
      final date = DateTime.tryParse(dateStr);
      if (date == null) {
        throw FormatException(
            'Event #${i + 1} has an invalid date: "$dateStr". Expected YYYY-MM-DD.');
      }

      // Parse optional end_date
      DateTime? endDate;
      final endDateStr = event['end_date'] as String?;
      if (endDateStr != null && endDateStr.isNotEmpty) {
        endDate = DateTime.tryParse(endDateStr);
        if (endDate == null) {
          throw FormatException(
              'Event #${i + 1} has an invalid end_date: "$endDateStr". Expected YYYY-MM-DD.');
        }
        // Ensure end_date is after start date
        if (endDate.isBefore(date)) {
          throw FormatException(
              'Event #${i + 1}: end_date ($endDateStr) is before date ($dateStr).');
        }
      }

      // Parse event name
      final name = event['name'] as String? ?? 'Unnamed Event';

      // Parse and validate event type
      final eventType = (event['type'] as String?)?.toLowerCase() ?? 'holiday';
      if (!validEventTypes.contains(eventType)) {
        throw FormatException(
            'Event #${i + 1} ("$name") has an invalid type: "$eventType". '
            'Valid types: ${validEventTypes.join(", ")}');
      }

      // Parse follows_day (only relevant for compensatory type)
      String? followsDay;
      if (eventType == 'compensatory') {
        followsDay = (event['follows_day'] as String?)?.toLowerCase();
        if (followsDay == null || !validWeekdays.contains(followsDay)) {
          throw FormatException(
              'Compensatory event #${i + 1} ("$name") must have a valid '
              '"follows_day" (e.g. "monday"). Got: "${event['follows_day']}".');
        }
      }

      // For vacation/exam types, if there's an end_date, we store
      // the range as a single row (not one row per day).
      // The DAO queries handle range matching.
      
      final startDate = DateTime(date.year, date.month, date.day);
      final finalEndDate = endDate != null 
          ? DateTime(endDate.year, endDate.month, endDate.day)
          : startDate;

      if (!clearExisting) {
        // If we are merging, overwrite any existing events on these dates
        await db.holidaysDao.deleteEventsInRange(startDate, finalEndDate);
      }

      companions.add(HolidaysCompanion.insert(
        date: startDate,
        endDate: endDate != null ? Value(finalEndDate) : const Value.absent(),
        label: Value(name),
        eventType: Value(eventType),
        followsDay: Value(followsDay),
      ));
    }

    // Bulk insert
    return await db.holidaysDao.bulkInsertHolidays(companions);
  }

  /// Generate the AI prompt template that users can copy and paste
  /// into ChatGPT/Gemini along with their academic calendar.
  static const String aiPromptTemplate = '''You are an academic calendar parser. I will provide you with an academic calendar (as an image, PDF text, or plain text). Your job is to extract ALL events and convert them into a structured JSON file.

CRITICAL INSTRUCTIONS:
1. You MUST generate and provide a DOWNLOADABLE .json FILE — not just JSON code in the chat. Name the file "academic_calendar.json".
2. Extract EVERY event you can find: holidays, vacations, exam periods, fests, compensatory working days, half-days, restricted holidays — everything.
3. For multi-day events (like "Winter Vacation: Dec 20 – Jan 2"), use the "end_date" field. Do NOT create one entry per day.
4. For compensatory working days (like "Saturday works as Monday"), set type to "compensatory" and include "follows_day" with the weekday name.
5. Dates MUST be in YYYY-MM-DD format.
6. If the year is not explicitly mentioned, infer it from context. If the calendar spans two years (e.g. Aug 2026 – May 2027), use the correct year for each date.

EVENT TYPE GUIDE — classify each event into exactly one of these:
• "holiday" → Full day off. National holidays, founder's day, etc.
• "exam" → Examination period. Regular classes are paused.
• "cancelled" → Classes cancelled for a reason (fest, convocation, sports day, etc.)
• "vacation" → Multi-day break (semester break, winter break, summer break). Always use end_date.
• "compensatory" → A normally-off day (Saturday/Sunday) that has classes. MUST include "follows_day" (e.g. "monday").
• "restricted" → Optional/restricted holiday. Students may or may not attend.
• "half_day_morning" → Morning classes cancelled, only afternoon classes happen.
• "half_day_afternoon" → Afternoon classes cancelled, only morning classes happen.

OUTPUT FORMAT — use this exact JSON structure:
{
  "type": "academic_calendar",
  "institution": "<name of the college/university>",
  "semester": "<semester/term name if visible>",
  "events": [
    {
      "date": "2026-10-24",
      "end_date": null,
      "name": "Diwali",
      "type": "holiday"
    },
    {
      "date": "2026-10-20",
      "end_date": "2026-10-23",
      "name": "Diwali Vacation",
      "type": "vacation"
    },
    {
      "date": "2026-11-15",
      "end_date": "2026-11-25",
      "name": "End Semester Examinations",
      "type": "exam"
    },
    {
      "date": "2026-09-28",
      "end_date": null,
      "name": "Saturday - Monday Timetable",
      "type": "compensatory",
      "follows_day": "monday"
    },
    {
      "date": "2026-12-01",
      "end_date": "2026-12-02",
      "name": "Annual Fest",
      "type": "cancelled"
    },
    {
      "date": "2026-08-15",
      "end_date": null,
      "name": "Independence Day (Half Day - Afternoon Off)",
      "type": "half_day_afternoon"
    }
  ]
}

RULES:
- "end_date" should be null for single-day events, and a date string for multi-day events.
- "follows_day" should ONLY be present for "compensatory" type events. For all other types, omit it or set to null.
- Include ALL events from the calendar, even if you're unsure of the type — make your best guess.
- Sort events by date in ascending order.
- If you see "Instructional days begin" or "Classes commence", you can skip those — they're not events that affect attendance.
- If the user provides an update to an existing calendar, just provide a JSON with the new or modified events. The app will automatically overwrite any existing events on those specific dates.

Remember: OUTPUT A DOWNLOADABLE .json FILE, not code in the chat.''';
}
