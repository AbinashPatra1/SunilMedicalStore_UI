import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/appointments/domain/admin_appointment.dart';
import 'package:sunil_medical_store/features/profile/domain/past_appointment.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/status_chip.dart';

/// Admin's row-per-appointment: user + doctor + date/time + status. Tap to
/// edit (reschedule / mark status).
class AdminAppointmentTile extends StatelessWidget {
  const AdminAppointmentTile({
    super.key,
    required this.appointment,
    required this.onTap,
  });

  final AdminAppointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = appointment.status != AppointmentStatus.cancelled;
    final when = DateFormat('EEE, d MMM • h:mm a').format(appointment.dateTime);

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
                    Text(
                      appointment.userName,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      appointment.userPhone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      '${appointment.doctorName} · ${appointment.specialization}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(when, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(label: appointment.status.label, positive: positive),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text('₹${appointment.fee}', style: theme.textTheme.titleSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
