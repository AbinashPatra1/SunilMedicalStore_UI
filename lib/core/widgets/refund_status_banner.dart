import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';

/// One-line refund outcome for a cancelled, online-paid order — shown on both
/// the customer's and the admin's order detail screens.
class RefundStatusBanner extends StatelessWidget {
  const RefundStatusBanner({super.key, required this.status});

  final RefundStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final failed = status == RefundStatus.failed;
    final background = failed ? scheme.errorContainer : scheme.primaryContainer.withValues(alpha: 0.5);
    final foreground = failed ? scheme.onErrorContainer : scheme.onPrimaryContainer;
    final icon = switch (status) {
      RefundStatus.pending => Icons.hourglass_top_outlined,
      RefundStatus.processed => Icons.check_circle_outline,
      RefundStatus.failed => Icons.error_outline,
    };

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              status.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: foreground, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
