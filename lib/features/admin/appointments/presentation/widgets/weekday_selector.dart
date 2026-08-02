import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';

/// Multi-select weekday chip row (Mon..Sun). Values are ISO weekday ints
/// (`DateTime.monday` = 1 .. `DateTime.sunday` = 7), matching the rest of
/// the appointments feature.
class WeekdaySelector extends StatelessWidget {
  const WeekdaySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;
  final bool enabled;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppConstants.spacingSm,
      children: [
        for (var i = 1; i <= 7; i++)
          FilterChip(
            label: Text(_labels[i - 1]),
            selected: selected.contains(i),
            onSelected: enabled
                ? (chosen) {
                    final next = Set<int>.from(selected);
                    if (chosen) {
                      next.add(i);
                    } else {
                      next.remove(i);
                    }
                    onChanged(next);
                  }
                : null,
          ),
      ],
    );
  }
}
