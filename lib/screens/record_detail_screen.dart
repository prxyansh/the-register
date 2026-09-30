import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/app_database.dart';
import '../data/providers.dart';
import '../data/attendance_status.dart';
import '../services/attendance_checker.dart';

/// Record detail screen — SPEC.md §10, Screen 6.
///
/// Shows confidence score, raw checks_json log in readable format,
/// and a button to manually override status with a required reason.
class RecordDetailScreen extends ConsumerStatefulWidget {
  final AttendanceRecord record;
  final Subject? subject;
  final TimetableEntry? entry;

  const RecordDetailScreen({
    super.key,
    required this.record,
    this.subject,
    this.entry,
  });

  @override
  ConsumerState<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends ConsumerState<RecordDetailScreen> {
  late AttendanceRecord _record;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  Future<void> _showOverrideDialog() async {
    String? selectedReason;
    final customController = TextEditingController();
    final reasons = ['Sick', 'Class Cancelled', 'Official Leave', 'Other'];

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Override Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a reason for overriding the detected status:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                RadioGroup<String>(
                  groupValue: selectedReason ?? '',
                  onChanged: (value) {
                    setDialogState(() => selectedReason = value);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: reasons.map((reason) => ListTile(
                          title: Text(reason),
                          leading: Radio<String>(value: reason),
                          onTap: () {
                            setDialogState(() => selectedReason = reason);
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        )).toList(),
                  ),
                ),
                if (selectedReason == 'Other') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: customController,
                    decoration: const InputDecoration(
                      labelText: 'Custom reason',
                      hintText: 'e.g., family emergency',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: selectedReason == null
                    ? null
                    : () {
                        final reason = selectedReason == 'Other'
                            ? customController.text.trim().isEmpty
                                ? 'Other'
                                : customController.text.trim()
                            : selectedReason!;
                        Navigator.pop(
                            context, {'status': 'manual_override', 'reason': reason});
                      },
                child: const Text('Override'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && mounted) {
      final dao = ref.read(attendanceRecordsDaoProvider);
      await dao.overrideRecord(
        _record.id,
        result['status']!,
        result['reason'],
      );

      // Refresh the record
      final updated = await dao.getRecordById(_record.id);
      setState(() => _record = updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status overridden: ${result['reason']}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = AttendanceStatus.fromDbValue(_record.status);

    // Parse check samples
    List<CheckSample> samples = [];
    try {
      final jsonList = jsonDecode(_record.checksJson) as List<dynamic>;
      samples = jsonList
          .map((e) => CheckSample.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          // Subject & date header
          _HeaderCard(
            subject: widget.subject,
            entry: widget.entry,
            record: _record,
            status: status,
            theme: theme,
          ),

          const SizedBox(height: 16),

          // Confidence score
          _ConfidenceSection(
            score: _record.confidenceScore,
            status: status,
            theme: theme,
          ),

          // Override reason (if overridden)
          if (_record.overrideReason != null) ...[
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
              child: ListTile(
                leading: Icon(Icons.edit_rounded,
                    color: theme.colorScheme.tertiary),
                title: const Text('Manual Override'),
                subtitle: Text(_record.overrideReason!),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Raw check log
          Text(
            'Detection Log',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          if (samples.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No detection samples recorded',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
            )
          else
            ...samples.asMap().entries.map((e) => _CheckSampleCard(
                  index: e.key + 1,
                  sample: e.value,
                  theme: theme,
                )),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.tonalIcon(
          onPressed: _showOverrideDialog,
          icon: const Icon(Icons.edit_rounded),
          label: Text(
            _record.overrideReason != null
                ? 'Change Override'
                : 'Override Status',
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Subject? subject;
  final TimetableEntry? entry;
  final AttendanceRecord record;
  final AttendanceStatus status;
  final ThemeData theme;

  const _HeaderCard({
    required this.subject,
    required this.entry,
    required this.record,
    required this.status,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final subjectColor =
        subject != null ? Color(subject!.color) : theme.colorScheme.outline;

    final (statusLabel, statusColor, statusIcon) = switch (status) {
      AttendanceStatus.present => ('Present', Colors.green.shade700, Icons.check_circle_rounded),
      AttendanceStatus.absent => ('Absent', theme.colorScheme.error, Icons.cancel_rounded),
      AttendanceStatus.ambiguous => ('Ambiguous', Colors.orange.shade700, Icons.help_rounded),
      AttendanceStatus.manualOverride => ('Override', theme.colorScheme.tertiary, Icons.edit_rounded),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: subjectColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject?.name ?? 'Unknown',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(record.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (entry != null)
                    Text(
                      '${entry!.startTime} – ${entry!.endTime}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceSection extends StatelessWidget {
  final double score;
  final AttendanceStatus status;
  final ThemeData theme;

  const _ConfidenceSection({
    required this.score,
    required this.status,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = switch (status) {
      AttendanceStatus.present => Colors.green.shade600,
      AttendanceStatus.absent => theme.colorScheme.error,
      AttendanceStatus.ambiguous => Colors.orange.shade600,
      AttendanceStatus.manualOverride => theme.colorScheme.tertiary,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Confidence Score',
                    style: theme.textTheme.titleSmall),
                Text(
                  '${(score * 100).round()}%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: barColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: score.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _confidenceExplanation(score),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _confidenceExplanation(double score) {
    if (score >= 0.8) return 'High confidence — strong signals you were present.';
    if (score <= 0.3) return 'Low confidence — signals suggest you were not at the venue.';
    return 'Mixed signals — detection was inconclusive. You can override if needed.';
  }
}

/// Displays a single check sample from the detection log.
class _CheckSampleCard extends StatelessWidget {
  final int index;
  final CheckSample sample;
  final ThemeData theme;

  const _CheckSampleCard({
    required this.index,
    required this.sample,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: check # + time
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: sample.insideRadius
                      ? Colors.green.shade100
                      : theme.colorScheme.errorContainer,
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: sample.insideRadius
                          ? Colors.green.shade800
                          : theme.colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('HH:mm:ss').format(sample.timestamp),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Overall sample score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _scoreColor(sample.sampleScore).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(sample.sampleScore * 100).round()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _scoreColor(sample.sampleScore),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Signal details
            Row(
              children: [
                _SignalChip(
                  icon: Icons.location_on_rounded,
                  label: '${sample.distanceMeters.round()}m',
                  score: sample.gpsScore,
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _SignalChip(
                  icon: Icons.wifi_rounded,
                  label: sample.connectedSsid ?? 'N/A',
                  score: sample.wifiScore,
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _SignalChip(
                  icon: Icons.directions_walk_rounded,
                  label: sample.isStationary == true ? 'Still' : 'Moving',
                  score: sample.motionScore,
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 0.7) return Colors.green.shade700;
    if (score >= 0.4) return Colors.orange.shade700;
    return Colors.red.shade700;
  }
}

class _SignalChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final double score;
  final ThemeData theme;

  const _SignalChip({
    required this.icon,
    required this.label,
    required this.score,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = score >= 0.7
        ? Colors.green.shade600
        : score >= 0.4
            ? Colors.orange.shade600
            : theme.colorScheme.error;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
