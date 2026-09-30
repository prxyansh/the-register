import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../theme/register_theme.dart';

/// Dialog for adding or editing a TimetableEntry.
/// Requires a list of available subjects to pick from.
class TimetableEntryFormDialog extends StatefulWidget {
  final List<Subject> subjects;
  final List<Venue> venues;
  final TimetableEntry? existingEntry; // null = adding new
  final int? preselectedSubjectId;

  const TimetableEntryFormDialog({
    super.key,
    required this.subjects,
    this.venues = const [],
    this.existingEntry,
    this.preselectedSubjectId,
  });

  @override
  State<TimetableEntryFormDialog> createState() =>
      _TimetableEntryFormDialogState();
}

class _TimetableEntryFormDialogState extends State<TimetableEntryFormDialog> {
  late int? _selectedSubjectId;
  late int? _selectedVenueId;
  late int _selectedDay;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.existingEntry;
    _selectedSubjectId = entry?.subjectId ??
        widget.preselectedSubjectId ??
        (widget.subjects.isNotEmpty ? widget.subjects.first.id : null);
    _selectedVenueId = entry?.venueId;
    _selectedDay = entry?.dayOfWeek ?? DateTime.now().weekday;
    _startTime = entry != null
        ? _parseTime(entry.startTime)
        : const TimeOfDay(hour: 9, minute: 0);
    _endTime = entry != null
        ? _parseTime(entry.endTime)
        : const TimeOfDay(hour: 10, minute: 0);
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeDisplay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.subjects.isEmpty) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'No Subjects Yet',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Please add at least one subject before creating a timetable entry.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                _isEditing ? 'Edit Class' : 'Add Class',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Subject picker
              Text(
                'Subject',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedSubjectId,
                decoration: InputDecoration(
                  prefixIcon: _selectedSubjectId != null
                      ? Padding(
                          padding: const EdgeInsets.only(left: 12, right: 4),
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: Color(
                              widget.subjects
                                  .firstWhere(
                                      (s) => s.id == _selectedSubjectId)
                                  .color,
                            ),
                          ),
                        )
                      : null,
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 36, minHeight: 0),
                ),
                items: widget.subjects.map((subject) {
                  return DropdownMenuItem<int>(
                    value: subject.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 6,
                          backgroundColor: Color(subject.color),
                        ),
                        const SizedBox(width: 10),
                        Flexible(child: Text(subject.name)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (id) => setState(() => _selectedSubjectId = id),
              ),
              const SizedBox(height: 20),

              // Day picker
              Text(
                'Day',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final isSelected = _selectedDay == day;
                  return ChoiceChip(
                    label: Text(RegisterTheme.dayShortNames[index]),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedDay = day),
                    showCheckmark: false,
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Time pickers
              Row(
                children: [
                  Expanded(
                    child: _buildTimePicker(
                      context,
                      label: 'Start Time',
                      time: _startTime,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (picked != null) {
                          setState(() => _startTime = picked);
                        }
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.arrow_forward_rounded, size: 20),
                  ),
                  Expanded(
                    child: _buildTimePicker(
                      context,
                      label: 'End Time',
                      time: _endTime,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (picked != null) {
                          setState(() => _endTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Venue picker (optional)
              if (widget.venues.isNotEmpty) ...[
                Text(
                  'Venue (optional)',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  initialValue: _selectedVenueId,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_rounded),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('No venue'),
                    ),
                    ...widget.venues.map((venue) {
                      return DropdownMenuItem<int?>(
                        value: venue.id,
                        child: Text(venue.name),
                      );
                    }),
                  ],
                  onChanged: (id) => setState(() => _selectedVenueId = id),
                ),
                const SizedBox(height: 20),
              ],

              // Validation hint
              if (_endTime.hour < _startTime.hour ||
                  (_endTime.hour == _startTime.hour &&
                      _endTime.minute <= _startTime.minute))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Text(
                        'End time must be after start time',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _canSubmit ? _submit : null,
                    child: Text(_isEditing ? 'Save' : 'Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canSubmit {
    if (_selectedSubjectId == null) return false;
    // End time must be after start time
    if (_endTime.hour < _startTime.hour) return false;
    if (_endTime.hour == _startTime.hour &&
        _endTime.minute <= _startTime.minute) {
      return false;
    }
    return true;
  }

  Widget _buildTimePicker(
    BuildContext context, {
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  _formatTimeDisplay(time),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _submit() {
    final result = {
      'subjectId': _selectedSubjectId,
      'venueId': _selectedVenueId,
      'dayOfWeek': _selectedDay,
      'startTime': _formatTime(_startTime),
      'endTime': _formatTime(_endTime),
    };
    Navigator.pop(context, result);
  }
}
