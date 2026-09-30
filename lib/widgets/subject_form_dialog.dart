import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../theme/register_theme.dart';
import '../widgets/color_picker_row.dart';

/// Dialog for adding or editing a Subject.
/// Returns the inserted/updated Subject on success, null on cancel.
class SubjectFormDialog extends StatefulWidget {
  final Subject? existingSubject; // null = adding new

  const SubjectFormDialog({super.key, this.existingSubject});

  @override
  State<SubjectFormDialog> createState() => _SubjectFormDialogState();
}

class _SubjectFormDialogState extends State<SubjectFormDialog> {
  late final TextEditingController _nameController;
  late int _selectedColor;
  late double _targetPct;
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.existingSubject != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingSubject?.name ?? '');
    _selectedColor = widget.existingSubject?.color ??
        RegisterTheme.subjectColors.first.toARGB32();
    _targetPct = widget.existingSubject?.targetAttendancePct ?? 75.0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(_selectedColor).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.book_rounded,
                      color: Color(_selectedColor),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEditing ? 'Edit Subject' : 'New Subject',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                  hintText: 'e.g. Data Structures',
                  prefixIcon: Icon(Icons.edit_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a subject name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Color picker
              Text(
                'Color',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ColorPickerRow(
                selectedColor: _selectedColor,
                onColorSelected: (color) =>
                    setState(() => _selectedColor = color),
              ),
              const SizedBox(height: 20),

              // Target attendance
              Row(
                children: [
                  Text(
                    'Target Attendance',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_targetPct.round()}%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _targetPct,
                min: 50,
                max: 100,
                divisions: 10,
                label: '${_targetPct.round()}%',
                onChanged: (v) => setState(() => _targetPct = v),
              ),
              const SizedBox(height: 16),

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
                    onPressed: _submit,
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final result = {
      'name': _nameController.text.trim(),
      'color': _selectedColor,
      'targetPct': _targetPct,
    };
    Navigator.pop(context, result);
  }
}
