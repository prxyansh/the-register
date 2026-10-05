import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/app_database.dart';
import '../data/providers.dart';
import '../data/attendance_status.dart';
import '../theme/register_theme.dart';
import '../widgets/register_row.dart';
import 'record_detail_screen.dart';

import '../services/location_service.dart';

final locationPermissionsProvider = FutureProvider.autoDispose<bool>((ref) async {
  final fg = await LocationService.hasForegroundPermission();
  final bg = await LocationService.hasBackgroundPermission();
  return fg && bg;
});

/// Home / Today screen — SPEC.md §10, Screen 4.
///
/// Shows today's classes from the timetable, each with a live status badge:
/// Upcoming / In Progress / Present / Absent / Ambiguous.
/// Uses Riverpod streams from Drift so the UI updates automatically
/// as records change during the day (no manual refresh needed).
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(todayEntriesProvider);
    final recordsAsync = ref.watch(todayRecordsProvider);
    final subjectsAsync = ref.watch(allSubjectsProvider);
    final venuesAsync = ref.watch(allVenuesProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Today'),
            Text(
              DateFormat('EEEE, d MMMM').format(now),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Consumer(
            builder: (context, ref, child) {
              final permissionsAsync = ref.watch(locationPermissionsProvider);
              return permissionsAsync.when(
                data: (hasPermissions) {
                  if (hasPermissions) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    color: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Text(
                      'Warning: Location permissions are missing. Auto-tracking is paused.',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onError,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
          Expanded(
            child: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return _buildNoClassesView(theme, now);
          }

          final subjects = subjectsAsync.valueOrNull ?? [];
          final records = recordsAsync.valueOrNull ?? [];
          final venues = venuesAsync.valueOrNull ?? [];

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: entries.length + 1, // +1 for header
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildDaySummary(theme, entries, records, subjects);
              }

              final entry = entries[index - 1];
              final subject = subjects.cast<Subject?>().firstWhere(
                    (s) => s!.id == entry.subjectId,
                    orElse: () => null,
                  );
              final record = records.cast<AttendanceRecord?>().firstWhere(
                    (r) => r!.timetableEntryId == entry.id,
                    orElse: () => null,
                  );
              final venue = entry.venueId != null
                  ? venues.cast<Venue?>().firstWhere(
                        (v) => v!.id == entry.venueId,
                        orElse: () => null,
                      )
                  : null;

              return _TodayClassCard(
                entry: entry,
                subject: subject,
                record: record,
                venue: venue,
                now: now,
              );
            },
          );
        },
      ),
    ),
    ],
    ),
    );
  }

  Widget _buildNoClassesView(ThemeData theme, DateTime now) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline, width: 4),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.weekend_rounded,
                size: 48,
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'NO CLASSES TODAY.\nGO TOUCH GRASS.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildDaySummary(ThemeData theme, List<TimetableEntry> entries,
      List<AttendanceRecord> records, List<Subject> subjects) {
    int presentCount = 0;
    int absentCount = 0;
    int ambiguousCount = 0;
    int pendingCount = 0;

    for (final entry in entries) {
      final record = records.cast<AttendanceRecord?>().firstWhere(
            (r) => r!.timetableEntryId == entry.id,
            orElse: () => null,
          );
      if (record == null) {
        pendingCount++;
      } else {
        final status = AttendanceStatus.fromDbValue(record.attendanceStatus);
        switch (status) {
          case AttendanceStatus.present:
            presentCount++;
          case AttendanceStatus.absent:
            absentCount++;
          case AttendanceStatus.ambiguous:
          case AttendanceStatus.unknown:
            ambiguousCount++;
        }
      }
    }

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerTheme.color ?? theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            label: 'Total',
            count: entries.length,
            color: isDark ? RegisterTheme.stampBlueDark : RegisterTheme.stampBlue,
          ),
          _SummaryItem(
            label: 'Present',
            count: presentCount,
            color: isDark ? RegisterTheme.presentDark : RegisterTheme.present,
          ),
          _SummaryItem(
            label: 'Absent',
            count: absentCount,
            color: isDark ? RegisterTheme.absentDark : RegisterTheme.absent,
          ),
          _SummaryItem(
            label: 'Pending',
            count: pendingCount + ambiguousCount,
            color: isDark ? RegisterTheme.ambiguousDark : RegisterTheme.ambiguous,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: RegisterTheme.data(color).copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: RegisterTheme.bodySmall(theme.colorScheme.outline),
        ),
      ],
    );
  }
}

/// Row showing a single class for today with live status via RegisterRow.
class _TodayClassCard extends ConsumerWidget {
  final TimetableEntry entry;
  final Subject? subject;
  final AttendanceRecord? record;
  final Venue? venue;
  final DateTime now;

  const _TodayClassCard({
    required this.entry,
    required this.subject,
    required this.record,
    required this.venue,
    required this.now,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RegisterRow(
      time: entry.startTime, // the spec uses "09:00", so 24h format fits
      title: subject?.name ?? 'Unknown Subject',
      subtitle: [
        if (subject?.facultyName != null && subject!.facultyName!.isNotEmpty) subject!.facultyName!,
        if (venue?.name != null && venue!.name.isNotEmpty) venue!.name,
      ].join(' • ').isNotEmpty ? [
        if (subject?.facultyName != null && subject!.facultyName!.isNotEmpty) subject!.facultyName!,
        if (venue?.name != null && venue!.name.isNotEmpty) venue!.name,
      ].join(' • ') : null,
      status: _determineStatus(),
      progress: _calculateProgress(),
      onTap: () async {
        HapticFeedback.selectionClick();
        var currentRecord = record;
        if (currentRecord == null) {
          // create a dummy pending record for manual override
          final dao = ref.read(attendanceRecordsDaoProvider);
          final id = await dao.insertRecord(
            AttendanceRecordsCompanion.insert(
              timetableEntryId: entry.id,
              date: DateTime(now.year, now.month, now.day),
              attendanceStatus: Value(AttendanceStatus.absent.toDbValue()),
            ),
          );
          currentRecord = await dao.getRecordById(id);
        }

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecordDetailScreen(
                record: currentRecord!,
                subject: subject,
                entry: entry,
              ),
            ),
          );
        }
      },
    );
  }

  AttendanceStatus? _determineStatus() {
    if (record != null) {
      return AttendanceStatus.fromDbValue(record!.attendanceStatus);
    }
    
    // Determine status from time
    final startParts = entry.startTime.split(':');
    final endParts = entry.endTime.split(':');
    final classStart = DateTime(
        now.year, now.month, now.day,
        int.parse(startParts[0]), int.parse(startParts[1]));
    final classEnd = DateTime(
        now.year, now.month, now.day,
        int.parse(endParts[0]), int.parse(endParts[1]));

    if (now.isBefore(classStart)) {
      return null; // Upcoming (empty outline)
    } else if (now.isBefore(classEnd)) {
      return AttendanceStatus.ambiguous; // In progress / pending (dotted outline)
    } else {
      return AttendanceStatus.absent; // Missed / No data (slash)
    }
  }
  
  double? _calculateProgress() {
    final startParts = entry.startTime.split(':');
    final endParts = entry.endTime.split(':');
    final classStart = DateTime(
        now.year, now.month, now.day,
        int.parse(startParts[0]), int.parse(startParts[1]));
    final classEnd = DateTime(
        now.year, now.month, now.day,
        int.parse(endParts[0]), int.parse(endParts[1]));
        
    if (now.isAfter(classStart) && now.isBefore(classEnd)) {
      final total = classEnd.difference(classStart).inSeconds;
      final elapsed = now.difference(classStart).inSeconds;
      if (total <= 0) return null;
      return (elapsed / total).clamp(0.0, 1.0);
    }
    return null;
  }
}
