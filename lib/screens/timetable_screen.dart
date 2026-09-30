import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull, Column;
import '../data/app_database.dart';
import '../data/providers.dart';
import '../theme/register_theme.dart';
import '../widgets/subject_form_dialog.dart';
import '../widgets/timetable_entry_form_dialog.dart';
import '../services/timetable_share_service.dart';
import 'venues_screen.dart';

/// Timetable setup screen — SPEC.md §10, Screen 2.
/// Shows all subjects and timetable entries.
/// Allows adding, editing, and deleting entries.
class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Timetable'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Timetable',
            onPressed: () => _showShareDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Import Timetable',
            onPressed: () => _showImportDialog(context, ref),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.book_rounded), text: 'Subjects'),
            Tab(icon: Icon(Icons.calendar_today_rounded), text: 'Classes'),
            Tab(icon: Icon(Icons.location_on_rounded), text: 'Venues'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SubjectsTab(),
          _ClassesTab(),
          _VenuesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onFabPressed(context),
        icon: const Icon(Icons.add_rounded),
        label: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            final labels = ['Add Subject', 'Add Class', 'Add Venue'];
            return Text(labels[_tabController.index]);
          },
        ),
      ),
    );
  }

  void _showShareDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copy Share Code'),
                subtitle: const Text('Paste in another device to import'),
                onTap: () async {
                  Navigator.pop(context);
                  final db = ref.read(databaseProvider);
                  final service = TimetableShareService(db);
                  final code = await service.generateShareCode();
                  await Clipboard.setData(ClipboardData(text: code));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share code copied to clipboard')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_upload_rounded),
                title: const Text('Export as JSON File'),
                subtitle: const Text('Save to your device or share'),
                onTap: () async {
                  Navigator.pop(context);
                  final db = ref.read(databaseProvider);
                  final service = TimetableShareService(db);
                  await service.shareJsonFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Import Timetable'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Paste Share Code',
                  hintText: 'Enter base64 code here',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text('OR', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.file_download_rounded),
                label: const Text('Pick JSON File'),
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final db = ref.read(databaseProvider);
                  final service = TimetableShareService(db);
                  try {
                    final count = await service.importFromJsonFile();
                    if (count > 0 && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Successfully imported $count classes!')),
                      );
                      ref.invalidate(allSubjectsProvider);
                      ref.invalidate(allTimetableEntriesProvider);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Import failed! Invalid JSON format. Check the "AI Import Guide" in Settings.'),
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final code = controller.text.trim();
                if (code.isEmpty) return;
                Navigator.pop(dialogContext);
                final db = ref.read(databaseProvider);
                final service = TimetableShareService(db);
                try {
                  final count = await service.importFromCode(code);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Successfully imported $count classes!')),
                    );
                    ref.invalidate(allSubjectsProvider);
                    ref.invalidate(allTimetableEntriesProvider);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Import failed! Invalid format. Check the "AI Import Guide" in Settings.'),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              child: const Text('Import Code'),
            ),
          ],
        );
      },
    );
  }

  void _onFabPressed(BuildContext context) {
    if (_tabController.index == 0) {
      _showAddSubjectDialog(context);
    } else if (_tabController.index == 1) {
      _showAddEntryDialog(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VenuesScreen()),
      );
    }
  }

  Future<void> _showAddSubjectDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const SubjectFormDialog(),
    );
    if (result != null && mounted) {
      await ref.read(subjectsDaoProvider).insertSubject(
            SubjectsCompanion.insert(
              name: result['name'] as String,
              color: result['color'] as int,
              targetAttendancePct: Value(result['targetPct'] as double),
            ),
          );
    }
  }

  Future<void> _showAddEntryDialog(BuildContext context) async {
    final subjects = await ref.read(subjectsDaoProvider).getAllSubjects();
    final venues = await ref.read(venuesDaoProvider).getAllVenues();
    if (!context.mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TimetableEntryFormDialog(
        subjects: subjects,
        venues: venues,
      ),
    );
    if (result != null) {
      await ref.read(timetableEntriesDaoProvider).insertEntry(
            TimetableEntriesCompanion.insert(
              subjectId: result['subjectId'] as int,
              dayOfWeek: result['dayOfWeek'] as int,
              startTime: result['startTime'] as String,
              endTime: result['endTime'] as String,
              venueId: Value(result['venueId'] as int?),
            ),
          );
    }
  }
}

/// Tab showing all subjects with edit/delete.
class _SubjectsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(allSubjectsProvider);
    final theme = Theme.of(context);

    return subjectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (subjects) {
        if (subjects.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No subjects yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first subject',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index];
            return _SubjectCard(subject: subject);
          },
        );
      },
    );
  }
}

class _SubjectCard extends ConsumerWidget {
  final Subject subject;

  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subjectColor = Color(subject.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _editSubject(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: subjectColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.book_rounded, color: subjectColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target: ${subject.targetAttendancePct.round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editSubject(context, ref);
                  } else if (value == 'delete') {
                    _deleteSubject(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded,
                            size: 18, color: theme.colorScheme.error),
                        const SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: theme.colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editSubject(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SubjectFormDialog(existingSubject: subject),
    );
    if (result != null) {
      await ref.read(subjectsDaoProvider).updateSubject(
            subject.copyWith(
              name: result['name'] as String,
              color: result['color'] as int,
              targetAttendancePct: result['targetPct'] as double,
            ),
          );
    }
  }

  Future<void> _deleteSubject(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text(
            'This will delete "${subject.name}" and all associated timetable entries.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(subjectsDaoProvider).deleteSubjectById(subject.id);
    }
  }
}

/// Tab showing all timetable entries grouped by day.
class _ClassesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allTimetableEntriesProvider);
    final subjectsAsync = ref.watch(allSubjectsProvider);
    final venuesAsync = ref.watch(allVenuesProvider);
    final theme = Theme.of(context);

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (entries) {
        return subjectsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (subjects) {
            if (entries.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No classes scheduled',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add subjects first, then schedule your classes',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            // Group entries by day
            final Map<int, List<TimetableEntry>> byDay = {};
            for (final entry in entries) {
              byDay.putIfAbsent(entry.dayOfWeek, () => []).add(entry);
            }

            // Sort entries within each day by start time
            for (final dayEntries in byDay.values) {
              dayEntries.sort((a, b) => a.startTime.compareTo(b.startTime));
            }

            // Sort days
            final sortedDays = byDay.keys.toList()..sort();

            // Get venues list (may still be loading)
            final venues = venuesAsync.valueOrNull ?? [];

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              itemCount: sortedDays.length,
              itemBuilder: (context, dayIndex) {
                final day = sortedDays[dayIndex];
                final dayEntries = byDay[day]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dayIndex > 0) const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: Text(
                        RegisterTheme.dayNames[day - 1],
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...dayEntries.map((entry) {
                      final subject = subjects.cast<Subject?>().firstWhere(
                            (s) => s!.id == entry.subjectId,
                            orElse: () => null,
                          );
                      final venue = entry.venueId != null
                          ? venues.cast<Venue?>().firstWhere(
                                (v) => v!.id == entry.venueId,
                                orElse: () => null,
                              )
                          : null;
                      return _TimetableEntryCard(
                        entry: entry,
                        subject: subject,
                        venue: venue,
                        allSubjects: subjects,
                        allVenues: venues,
                      );
                    }),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _TimetableEntryCard extends ConsumerWidget {
  final TimetableEntry entry;
  final Subject? subject;
  final Venue? venue;
  final List<Subject> allSubjects;
  final List<Venue> allVenues;

  const _TimetableEntryCard({
    required this.entry,
    required this.subject,
    this.venue,
    required this.allSubjects,
    required this.allVenues,
  });

  String _formatTimeDisplay(String time24) {
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subjectColor =
        subject != null ? Color(subject!.color) : theme.colorScheme.outline;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _editEntry(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Color bar
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: subjectColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              // Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTimeDisplay(entry.startTime),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatTimeDisplay(entry.endTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Subject name + venue
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject?.name ?? 'Unknown Subject',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (venue != null)
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 12, color: theme.colorScheme.outline),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              venue!.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Active toggle & menu
              if (!entry.active)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Inactive',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editEntry(context, ref);
                  } else if (value == 'toggle') {
                    _toggleActive(ref);
                  } else if (value == 'delete') {
                    _deleteEntry(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          entry.active
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(entry.active ? 'Mark Inactive' : 'Mark Active'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded,
                            size: 18, color: theme.colorScheme.error),
                        const SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: theme.colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editEntry(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TimetableEntryFormDialog(
        subjects: allSubjects,
        venues: allVenues,
        existingEntry: entry,
      ),
    );
    if (result != null) {
      await ref.read(timetableEntriesDaoProvider).updateEntry(
            entry.copyWith(
              subjectId: result['subjectId'] as int,
              dayOfWeek: result['dayOfWeek'] as int,
              startTime: result['startTime'] as String,
              endTime: result['endTime'] as String,
              venueId: Value(result['venueId'] as int?),
            ),
          );
    }
  }

  Future<void> _toggleActive(WidgetRef ref) async {
    await ref
        .read(timetableEntriesDaoProvider)
        .toggleActive(entry.id, !entry.active);
  }

  Future<void> _deleteEntry(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class?'),
        content:
            const Text('This timetable entry will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(timetableEntriesDaoProvider).deleteEntryById(entry.id);
    }
  }
}

/// Tab showing venues with a link to the Venues screen.
class _VenuesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(allVenuesProvider);
    final theme = Theme.of(context);

    return venuesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (venues) {
        if (venues.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_off_rounded,
                    size: 64,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No venues yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Venues are the physical locations of your classes.\n'
                    'Add venues so the app can detect your attendance.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          itemCount: venues.length,
          itemBuilder: (context, index) {
            final venue = venues[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.location_on_rounded,
                      color: theme.colorScheme.secondary),
                ),
                title: Text(venue.name),
                subtitle: Text(
                  '${venue.radiusMeters.round()}m radius'
                  '${venue.wifiSsid != null ? ' · WiFi: ${venue.wifiSsid}' : ''}',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VenuesScreen(),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
