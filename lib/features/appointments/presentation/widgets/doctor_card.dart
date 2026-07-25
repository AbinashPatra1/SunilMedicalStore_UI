import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/utils/week_range.dart';
import 'package:sunil_medical_store/features/appointments/domain/doctor.dart';
import 'package:sunil_medical_store/features/appointments/presentation/widgets/weekly_availability.dart';

/// Card showing a doctor's details and their availability for the current week.
class DoctorCard extends StatelessWidget {
  const DoctorCard({
    super.key,
    required this.doctor,
    required this.week,
    required this.onBook,
  });

  final Doctor doctor;
  final WeekRange week;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    doctor.initials,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor.name, style: theme.textTheme.titleMedium),
                      Text(
                        doctor.specialization,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        doctor.qualification,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Row(
              children: [
                _MetaChip(
                  icon: Icons.workspace_premium_outlined,
                  label: '${doctor.experienceYears} yrs exp',
                ),
                const SizedBox(width: AppConstants.spacingSm),
                _MetaChip(
                  icon: Icons.star_rounded,
                  label: doctor.rating.toStringAsFixed(1),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                _MetaChip(
                  icon: Icons.currency_rupee,
                  label: '${doctor.consultationFee}',
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppConstants.spacingXs),
                Text(
                  doctor.availableTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),
            WeeklyAvailability(
              week: week,
              availableWeekdays: doctor.availableWeekdays,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: onBook,
                icon: const Icon(Icons.event_available_outlined),
                label: const Text('Book appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 2),
        Text(label, style: theme.textTheme.labelMedium),
      ],
    );
  }
}
