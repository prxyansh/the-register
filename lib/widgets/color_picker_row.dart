import 'package:flutter/material.dart';
import '../theme/register_theme.dart';

/// A horizontal grid of color options for selecting a subject color.
class ColorPickerRow extends StatelessWidget {
  final int selectedColor;
  final ValueChanged<int> onColorSelected;

  const ColorPickerRow({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: RegisterTheme.subjectColors.map((color) {
        final isSelected = color.toARGB32() == selectedColor;
        return GestureDetector(
          onTap: () => onColorSelected(color.toARGB32()),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 3,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
