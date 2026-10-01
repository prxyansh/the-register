import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/providers.dart';
import '../data/attendance_status.dart';
import '../theme/register_theme.dart';
import '../widgets/register_row.dart';
import 'record_detail_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late PageController _pageController;
  final int _initialPage = 1200;
  late DateTime _baseMonth;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month, 1);
    _currentMonth = _baseMonth;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _monthForIndex(int index) {
    int offset = index - _initialPage;
    return DateTime(_baseMonth.year, _baseMonth.month + offset, 1);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentMonth = _monthForIndex(index);
    });
  }

  void _navigateMonth(int delta) {
    final nextIndex = _pageController.page!.round() + delta;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _pageController.jumpToPage(nextIndex);
    } else {
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthFormat = DateFormat('MMMM yyyy');

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Calendar', style: RegisterTheme.h1(theme.colorScheme.onSurface)),
        backgroundColor: theme.colorScheme.surface,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _navigateMonth(-1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _navigateMonth(1),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  monthFormat.format(_currentMonth),
                  style: RegisterTheme.h1(theme.colorScheme.onSurface).copyWith(fontSize: 24),
                ),
              ],
            ),
          ),
          _buildWeekdayHeaders(theme),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                return _MonthView(month: _monthForIndex(index));
              },
            ),
          ),
          _buildLegend(theme),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders(ThemeData theme) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((d) {
          return SizedBox(
            width: 40,
            child: Text(
              d,
              textAlign: TextAlign.center,
              style: RegisterTheme.bodySmall(theme.colorScheme.onSurfaceVariant),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerTheme.color ?? theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(color: isDark ? RegisterTheme.presentDark : RegisterTheme.present, label: 'Present'),
          const SizedBox(width: 16),
          _LegendItem(color: isDark ? RegisterTheme.ambiguousDark : RegisterTheme.ambiguous, label: 'Ambiguous'),
          const SizedBox(width: 16),
          _LegendItem(color: isDark ? RegisterTheme.absentDark : RegisterTheme.absent, label: 'Absent'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: RegisterTheme.bodySmall(theme.colorScheme.onSurface),
        ),
      ],
    );
  }
}

class _MonthView extends ConsumerWidget {
  final DateTime month;

  const _MonthView({required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsForMonthProvider(month));
    final entriesAsync = ref.watch(allTimetableEntriesProvider);
    final subjectsAsync = ref.watch(allSubjectsProvider);
    final venuesAsync = ref.watch(allVenuesProvider);

    if (recordsAsync.isLoading || entriesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final records = recordsAsync.valueOrNull ?? [];
    final entries = entriesAsync.valueOrNull ?? [];
    final subjects = subjectsAsync.valueOrNull ?? [];
    final venues = venuesAsync.valueOrNull ?? [];

    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstDayOffset = firstDay.weekday - 1; 

    final totalCells = (firstDayOffset + daysInMonth / 7).ceil() * 7;
    final gridCells = totalCells < (firstDayOffset + daysInMonth) ? totalCells + 7 : totalCells;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
      ),
      itemCount: gridCells,
      itemBuilder: (context, index) {
        final date = firstDay.add(Duration(days: index - firstDayOffset));
        final isCurrentMonth = date.month == month.month;
        return _DateCell(
          date: date,
          isCurrentMonth: isCurrentMonth,
          records: records,
          allEntries: entries,
          allSubjects: subjects,
          allVenues: venues,
        );
      },
    );
  }
}

class _DateCell extends ConsumerWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final List<AttendanceRecord> records;
  final List<TimetableEntry> allEntries;
  final List<Subject> allSubjects;
  final List<Venue> allVenues;

  const _DateCell({
    required this.date,
    required this.isCurrentMonth,
    required this.records,
    required this.allEntries,
    required this.allSubjects,
    required this.allVenues,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    final todayEntries = allEntries.where((e) => e.dayOfWeek == date.weekday).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final dayRecords = records.where((r) => r.date.year == date.year && r.date.month == date.month && r.date.day == date.day).toList();

    return InkWell(
      onTap: () {
        if (todayEntries.isEmpty) return;
        _showDayDetail(context, ref, date, todayEntries, dayRecords, allSubjects, allVenues);
      },
      child: Container(
        decoration: isToday ? BoxDecoration(
          border: Border.all(color: theme.colorScheme.onSurface, width: 2),
          borderRadius: BorderRadius.circular(8),
        ) : null,
        margin: const EdgeInsets.all(2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: RegisterTheme.data(
                isCurrentMonth 
                  ? theme.colorScheme.onSurface 
                  : theme.colorScheme.onSurface.withValues(alpha: 0.3)
              ),
            ),
            if (todayEntries.isNotEmpty)
              _buildDots(theme, isDark, todayEntries, dayRecords, date),
          ],
        ),
      ),
    );
  }

  AttendanceStatus? _determineStatus(DateTime date, TimetableEntry entry, AttendanceRecord? record) {
    if (record != null) {
      return AttendanceStatus.fromDbValue(record.status);
    }
    
    final now = DateTime.now();
    final startParts = entry.startTime.split(':');
    final endParts = entry.endTime.split(':');
    
    final classStart = DateTime(
        date.year, date.month, date.day,
        int.parse(startParts[0]), int.parse(startParts[1]));
    final classEnd = DateTime(
        date.year, date.month, date.day,
        int.parse(endParts[0]), int.parse(endParts[1]));

    if (now.isBefore(classStart)) {
      return null;
    } else if (now.isBefore(classEnd)) {
      return AttendanceStatus.ambiguous;
    } else {
      return AttendanceStatus.absent;
    }
  }

  Widget _buildDots(ThemeData theme, bool isDark, List<TimetableEntry> entries, List<AttendanceRecord> dayRecords, DateTime date) {
    List<Widget> dots = [];
    final displayCount = entries.length > 4 ? 4 : entries.length;

    for (int i = 0; i < displayCount; i++) {
      if (i == 3 && entries.length > 4) {
        dots.add(Padding(
          padding: const EdgeInsets.only(left: 1.0),
          child: Text(
            '+${entries.length - 3}',
            style: RegisterTheme.data(theme.colorScheme.onSurface).copyWith(fontSize: 8),
          ),
        ));
        break;
      }

      final entry = entries[i];
      final record = dayRecords.cast<AttendanceRecord?>().firstWhere((r) => r!.timetableEntryId == entry.id, orElse: () => null);
      
      final effectiveStatus = _determineStatus(date, entry, record);

      Color? dotColor;
      bool isOutline = false;

      if (effectiveStatus != null) {
        switch (effectiveStatus) {
          case AttendanceStatus.present:
          case AttendanceStatus.manualOverride:
            dotColor = isDark ? RegisterTheme.presentDark : RegisterTheme.present;
            break;
          case AttendanceStatus.absent:
            dotColor = isDark ? RegisterTheme.absentDark : RegisterTheme.absent;
            break;
          case AttendanceStatus.ambiguous:
            dotColor = isDark ? RegisterTheme.ambiguousDark : RegisterTheme.ambiguous;
            break;
        }
      } else {
        isOutline = true;
        dotColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);
      }

      dots.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isOutline ? Colors.transparent : dotColor,
            border: isOutline ? Border.all(color: dotColor!, width: 1) : null,
            shape: BoxShape.circle,
          ),
        )
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: dots,
      ),
    );
  }

  void _showDayDetail(BuildContext context, WidgetRef ref, DateTime date, List<TimetableEntry> entries, List<AttendanceRecord> records, List<Subject> subjects, List<Venue> venues) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMM d');

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  dateFormat.format(date),
                  style: RegisterTheme.h2(theme.colorScheme.onSurface),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final subject = subjects.cast<Subject?>().firstWhere((s) => s!.id == entry.subjectId, orElse: () => null);
                    final venue = entry.venueId != null ? venues.cast<Venue?>().firstWhere((v) => v!.id == entry.venueId, orElse: () => null) : null;
                    final record = records.cast<AttendanceRecord?>().firstWhere((r) => r!.timetableEntryId == entry.id, orElse: () => null);
                    
                    final status = _determineStatus(date, entry, record);

                    return RegisterRow(
                      time: entry.startTime,
                      title: subject?.name ?? 'Unknown',
                      subtitle: [
                        if (subject?.facultyName != null && subject!.facultyName!.isNotEmpty) subject.facultyName!,
                        if (venue?.name != null && venue!.name.isNotEmpty) venue.name,
                      ].join(' • ').isNotEmpty ? [
                        if (subject?.facultyName != null && subject!.facultyName!.isNotEmpty) subject.facultyName!,
                        if (venue?.name != null && venue!.name.isNotEmpty) venue.name,
                      ].join(' • ') : null,
                      status: status,
                      onTap: () async {
                        var currentRecord = record;
                        if (currentRecord == null) {
                          // create a dummy pending record for manual override
                          final dao = ref.read(attendanceRecordsDaoProvider);
                          final id = await dao.insertRecord(
                            AttendanceRecordsCompanion.insert(
                              timetableEntryId: entry.id,
                              date: DateTime(date.year, date.month, date.day),
                              status: AttendanceStatus.absent.toDbValue(),
                            ),
                          );
                          currentRecord = await dao.getRecordById(id);
                        }
                        
                        if (context.mounted) {
                          Navigator.pop(context); // Close bottom sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecordDetailScreen(
                                record: currentRecord!,
                                subject: subject,
                                entry: entry,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
