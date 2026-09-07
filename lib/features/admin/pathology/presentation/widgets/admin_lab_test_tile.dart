import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/pathology/domain/admin_lab_test_booking.dart';
import 'package:sunil_medical_store/features/profile/domain/lab_test.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/status_chip.dart';

/// Admin's row-per-booking: user + test name + scheduled date/time + status.
/// Tap to view/advance.
class AdminLabTestTile extends StatelessWidget {
  const AdminLabTestTile({super.key, required this.booking, required this.onTap});

  final AdminLabTestBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = booking.status != LabTestStatus.cancelled;
    final when = DateFormat('EEE, d MMM yyyy').format(booking.bookedOn);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.name, style: theme.textTheme.titleSmall),
                    if (booking.bookingNumber != null)
                      Text(
                        booking.bookingNumber!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      booking.userName,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                    ),
                    Text(
                      booking.userPhone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      '$when${booking.timeSlot != null ? ' • ${booking.timeSlot}' : ''}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(label: booking.status.label, positive: positive),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text('₹${booking.amount}', style: theme.textTheme.titleSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
