import 'package:flutter/material.dart';

/// Row of 5 stars. Read-only when [onChanged] is null (renders [value]
/// filled stars); otherwise each star is tappable and reports the 1–5
/// value tapped, for picking a new rating.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.value, this.onChanged, this.size = 22});

  final int value;
  final ValueChanged<int>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          if (onChanged == null)
            Icon(i <= value ? Icons.star_rounded : Icons.star_border_rounded, color: color, size: size)
          else
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              iconSize: size,
              onPressed: () => onChanged!(i),
              icon: Icon(i <= value ? Icons.star_rounded : Icons.star_border_rounded, color: color),
            ),
      ],
    );
  }
}
