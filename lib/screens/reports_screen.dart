import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/providers.dart';
import '../domain/report_calculator.dart';
import '../theme/register_theme.dart';
import '../widgets/split_flap_digit.dart';

/// Reports screen — SPEC.md §10, Screen 5.
///
/// Shows per-subject attendance percentage, bunk budget,
/// and a weekly trend view. All data updates reactively
/// as attendance records change.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(allSubjectsProvider);
    final entriesAsync = ref.watch(allTimetableEntriesProvider);
    final recordsAsync = ref.watch(allRecordsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (subjects) {
          final entries = entriesAsync.valueOrNull ?? [];
          final records = recordsAsync.valueOrNull ?? [];

          if (subjects.isEmpty) {
            return _buildEmptyState(theme);
          }

          final reports = computeReports(
            subjects: subjects,
            entries: entries,
            records: records,
          );

          final weeklyTrend = computeWeeklyTrend(records);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              // Overall summary
              _OverallSummary(reports: reports, theme: theme),
              const SizedBox(height: 24),

              // Per-subject rows
              Text(
                'By Subject',
                style: RegisterTheme.body(theme.colorScheme.onSurface).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...reports.map((report) => _SubjectReportRow(
                    report: report,
                    theme: theme,
                  )),

              // Weekly trend
              if (weeklyTrend.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Weekly Trend',
                  style: RegisterTheme.body(theme.colorScheme.onSurface).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _WeeklyTrendCard(trends: weeklyTrend, theme: theme),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 80,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No data yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add subjects and classes in the Timetable tab\nto start tracking attendance.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overall attendance summary across all subjects.
class _OverallSummary extends StatelessWidget {
  final List<SubjectReport> reports;
  final ThemeData theme;

  const _OverallSummary({required this.reports, required this.theme});

  @override
  Widget build(BuildContext context) {
    final totalScheduled = reports.fold(0, (sum, r) => sum + r.totalScheduled);
    final totalPresent = reports.fold(0, (sum, r) => sum + r.presentCount);
    final totalAbsent = reports.fold(0, (sum, r) => sum + r.absentCount);
    final overallPct =
        totalScheduled > 0 ? (totalPresent / totalScheduled) * 100.0 : 0.0;

    final isDark = theme.brightness == Brightness.dark;
    final pctColor = overallPct >= 75
        ? (isDark ? RegisterTheme.presentDark : RegisterTheme.present)
        : overallPct >= 50
            ? (isDark ? RegisterTheme.ambiguousDark : RegisterTheme.ambiguous)
            : (isDark ? RegisterTheme.absentDark : RegisterTheme.absent);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerTheme.color ?? theme.dividerColor)),
      ),
      child: Column(
          children: [
            Text(
              'Overall Attendance',
              style: RegisterTheme.bodySmall(theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            // Big percentage
            Text(
              '${overallPct.toStringAsFixed(1)}%',
              style: RegisterTheme.data(pctColor).copyWith(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  label: 'Classes',
                  value: '$totalScheduled',
                  theme: theme,
                ),
                _StatItem(
                  label: 'Present',
                  value: '$totalPresent',
                  theme: theme,
                ),
                _StatItem(
                  label: 'Absent',
                  value: '$totalAbsent',
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _StatItem({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: RegisterTheme.data(theme.colorScheme.onSurface).copyWith(
            fontSize: 20,
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

/// Per-subject attendance row with progress bar and bunk budget.
class _SubjectReportRow extends StatelessWidget {
  final SubjectReport report;
  final ThemeData theme;

  const _SubjectReportRow({required this.report, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final subjectColor = Color(report.subject.color);
    final pct = report.attendancePct;
    final target = report.subject.targetAttendancePct.toDouble();
    final budget = report.bunkBudget();
    final isAbove = report.isAboveTarget;
    
    final statusColor = isAbove 
        ? (isDark ? RegisterTheme.presentDark : RegisterTheme.present)
        : (isDark ? RegisterTheme.absentDark : RegisterTheme.absent);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerTheme.color ?? theme.dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Subject, percentages, progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: subjectColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        report.subject.name,
                        style: RegisterTheme.body(theme.colorScheme.onSurface).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${report.presentCount} / ${report.totalScheduled - report.excusedCount} classes • ${pct.toStringAsFixed(1)}%',
                  style: RegisterTheme.bodySmall(theme.colorScheme.outline),
                ),
                const SizedBox(height: 12),
                
                // Progress bar with target marker
                Stack(
                  children: [
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (pct / 100).clamp(0.0, 1.0),
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Target marker line
                    Positioned(
                      left: 0,
                      right: 0,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (target / 100).clamp(0.0, 1.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 2,
                            height: 10,
                            margin: const EdgeInsets.only(top: -3),
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Target: ${report.subject.targetAttendancePct}%',
                  style: RegisterTheme.bodySmall(theme.colorScheme.outline).copyWith(fontSize: 11),
                ),
                
                if (report.excusedCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${report.excusedCount} excused (not counted)',
                    style: RegisterTheme.bodySmall(theme.colorScheme.outline).copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right side: Bunk budget readout
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'BUDGET',
                style: RegisterTheme.bodySmall(theme.colorScheme.outline).copyWith(
                  letterSpacing: 1.2,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (budget < 0)
                    Text(
                      '-',
                      style: RegisterTheme.data(statusColor).copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  SplitFlapDigit(
                    value: budget.abs(),
                    textStyle: RegisterTheme.data(statusColor).copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                budget >= 0 ? 'safe to miss' : 'short of target',
                style: RegisterTheme.bodySmall(statusColor).copyWith(
                  fontWeight: budget < 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Weekly trend card showing attendance history.
class _WeeklyTrendCard extends StatelessWidget {
  final List<WeeklyTrend> trends;
  final ThemeData theme;

  const _WeeklyTrendCard({required this.trends, required this.theme});

  @override
  Widget build(BuildContext context) {
    // Show last 8 weeks max
    final recentTrends = trends.length > 8
        ? trends.sublist(trends.length - 8)
        : trends;

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple bar chart
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: recentTrends.map((trend) {
                final barHeight = (trend.attendancePct / 100.0) * 100;
                final barColor = trend.attendancePct >= 75
                    ? (isDark ? RegisterTheme.presentDark : RegisterTheme.present)
                    : trend.attendancePct >= 50
                        ? (isDark ? RegisterTheme.ambiguousDark : RegisterTheme.ambiguous)
                        : (isDark ? RegisterTheme.absentDark : RegisterTheme.absent);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${trend.attendancePct.round()}%',
                          style: RegisterTheme.data(theme.colorScheme.onSurfaceVariant).copyWith(
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight.clamp(4.0, 100.0),
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Week labels
          Row(
            children: recentTrends.map((trend) {
              return Expanded(
                child: Text(
                  DateFormat('d/M').format(trend.weekStart),
                  textAlign: TextAlign.center,
                  style: RegisterTheme.bodySmall(theme.colorScheme.outline).copyWith(
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
