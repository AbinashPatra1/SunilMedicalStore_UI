import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/theme/app_palette.dart';

/// A small pill showing an order/appointment/lab-test/prescription status.
///
/// Colour follows the status wording so every kind of status reads the same
/// way: waiting = amber, in progress = sky, shipped = lavender, done = mint,
/// cancelled/rejected = pink. Anything unrecognised falls back to
/// [positive] (mint) or negative (pink).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.positive = true});

  final String label;

  /// Used only when [label] isn't a known status.
  final bool positive;

  AppAccent get _accent => switch (label.toLowerCase()) {
    'created' || 'scheduled' || 'upcoming' || 'pending' || 'pending review' || 'exhausted' => AppAccent.amber,
    'processing' || 'in session' => AppAccent.sky,
    'shipped' => AppAccent.lavender,
    'delivered' || 'completed' || 'approved' || 'active' => AppAccent.mint,
    'cancelled' || 'rejected' || 'expired' || 'inactive' => AppAccent.pink,
    _ => positive ? AppAccent.mint : AppAccent.pink,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSm + 2, vertical: 3),
      decoration: BoxDecoration(color: accent.pastel, borderRadius: BorderRadius.circular(AppConstants.radiusFull)),
      child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: accent.ink, fontWeight: FontWeight.w700)),
    );
  }
}
