import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../data/providers.dart';
import '../services/backup_service.dart';

/// Settings screen — SPEC.md §10, Screen 7.
///
/// Export (JSON + CSV) via share sheet, import from JSON backup,
/// and weekly export reminder banner.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _exporting = false;
  bool _importing = false;
  String? _lastExportDate;

  @override
  void initState() {
    super.initState();
    _loadLastExportDate();
  }

  Future<void> _loadLastExportDate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastExportDate = prefs.getString('last_export_date');
    });
  }

  Future<void> _saveExportDate() async {
    final now = DateTime.now().toIso8601String();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_export_date', now);
    setState(() => _lastExportDate = now);
  }

  bool get _shouldShowExportReminder {
    if (_lastExportDate == null) return true;
    try {
      final last = DateTime.parse(_lastExportDate!);
      return DateTime.now().difference(last).inDays >= 7;
    } catch (_) {
      return true;
    }
  }

  Future<void> _exportJson() async {
    setState(() => _exporting = true);
    try {
      final db = ref.read(databaseProvider);
      final service = BackupService(db);
      final path = await service.exportJson();
      await _saveExportDate();
      await service.shareFile(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('JSON backup exported'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final db = ref.read(databaseProvider);
      final service = BackupService(db);
      final path = await service.exportCsv();
      await service.shareFile(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV exported'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV export failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _importJson() async {
    // List available backup files
    final backupFiles = await BackupService.listBackupFiles();

    if (!mounted) return;

    if (backupFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No backup files found. Export a backup first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show file selection dialog
    final selectedFile = await showDialog<File>(
      context: context,
      builder: (context) {
        final dateFormat = DateFormat('d MMM yyyy, h:mm a');
        return AlertDialog(
          title: const Text('Select Backup'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: backupFiles.length,
              itemBuilder: (context, index) {
                final file = backupFiles[index];
                final name = file.path.split('/').last;
                final modified = file.lastModifiedSync();
                return ListTile(
                  leading: const Icon(Icons.description_rounded),
                  title: Text(name, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(dateFormat.format(modified)),
                  onTap: () => Navigator.pop(context, file),
                  dense: true,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedFile == null || !mounted) return;

    final content = await selectedFile.readAsString();

    // Confirmation dialog
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, size: 32),
        title: const Text('Import Backup'),
        content: const Text(
          'This will merge imported data with your existing data. '
          'Duplicate entries may be skipped.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _importing = true);
    try {
      final db = ref.read(databaseProvider);
      final service = BackupService(db);
      final importResult = await service.importJson(content);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported: $importResult'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _showAIGuideDialog(BuildContext context) {
    const promptText = '''Please read this timetable image and convert it into the following strict JSON format. Do not add any text before or after the JSON block.

```json
{
  "type": "timetable_share",
  "version": 1,
  "subjects": [
    {
      "id": 1,
      "name": "Data Structures",
      "color": 4293322470,
      "target_attendance_pct": 75.0,
      "faculty_name": "Prof. Smith"
    },
    {
      "id": 2,
      "name": "Computer Networks",
      "color": 4283215696,
      "target_attendance_pct": 75.0
    }
  ],
  "entries": [
    {
      "subject_id": 1,
      "day_of_week": 1, 
      "start_time": "09:00",
      "end_time": "10:00"
    },
    {
      "subject_id": 2,
      "day_of_week": 2,
      "start_time": "10:00",
      "end_time": "11:00"
    }
  ]
}
```
Notes for AI:
- day_of_week: 1 is Monday, 7 is Sunday.
- color: Just use 4282339765 for all subjects if you don't know what to put.
- subject_id in the entries list must match the id in the subjects list.
- Time must be in 24-hour HH:MM format.
- faculty_name is optional. If you see a teacher's name, include it.''';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AI Import Guide'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('You can ask ChatGPT or Gemini to convert a picture of your timetable into a JSON file we can import!'),
              SizedBox(height: 16),
              Text('Just copy the prompt below and paste it along with your image:'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: promptText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prompt copied to clipboard!'))
              );
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('COPY PROMPT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          // Export reminder banner
          if (_shouldShowExportReminder)
            Card(
              color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: Icon(Icons.backup_rounded,
                    color: theme.colorScheme.tertiary),
                title: const Text('Backup recommended'),
                subtitle: Text(
                  _lastExportDate != null
                      ? 'Last export: ${DateFormat('d MMM yyyy').format(DateTime.parse(_lastExportDate!))}'
                      : 'You haven\'t exported your data yet',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    // Dismiss for now — will show again if 7+ days pass
                    await _saveExportDate();
                  },
                ),
              ),
            ),

          // Export section
          Text(
            'Export',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.data_object_rounded),
                  title: const Text('Export as JSON'),
                  subtitle: const Text('Full backup — can be imported back'),
                  trailing: _exporting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share_rounded),
                  onTap: _exporting ? null : _exportJson,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.table_chart_rounded),
                  title: const Text('Export as CSV'),
                  subtitle: const Text('Human-readable attendance spreadsheet'),
                  trailing: _exporting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share_rounded),
                  onTap: _exporting ? null : _exportCsv,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Import section
          Text(
            'Import',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_open_rounded),
                  title: const Text('Import from JSON'),
                  subtitle: const Text('Restore a previous backup'),
                  trailing: _importing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_rounded),
                  onTap: _importing ? null : _importJson,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.smart_toy_rounded),
                  title: const Text('AI Import Guide'),
                  subtitle: const Text('Convert images to JSON with ChatGPT'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => _showAIGuideDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About section
          Text(
            'About',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('Attendance Tracker'),
                  subtitle: Text('Version 1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.warning_amber_rounded,
                      color: theme.colorScheme.outline),
                  title: Text(
                    'Not an official record',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                  subtitle: Text(
                    'This app is a personal self-tracker. '
                    'It is not an official attendance system.',
                    style: TextStyle(
                        color: theme.colorScheme.outline, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: Text(
              'CRAFTED WITH 🚬 AND PRECISION\n— prx.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.outline,
                letterSpacing: 2,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
