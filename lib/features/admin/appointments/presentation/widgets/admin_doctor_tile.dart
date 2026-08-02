import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/appointments/domain/doctor.dart';

/// Admin-side compact doctor row: avatar initials + name + specialization +
/// availability summary. Tap to edit.
class AdminDoctorTile extends StatelessWidget {
  const AdminDoctorTile({super.key, required this.doctor, required this.onTap});

  final Doctor doctor;
  final VoidCallback onTap;

  static const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String get _weekdaySummary {
    if (doctor.availableWeekdays.isEmpty) return 'No days set';
    final sorted = [...doctor.availableWeekdays]..sort();
    return sorted.map((w) => _weekdayLabels[w - 1]).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedFee = NumberFormat.decimalPattern('en_IN').format(doctor.consultationFee);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  doctor.initials,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor.name, style: theme.textTheme.titleSmall),
                    Text(
                      doctor.specialization,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      '$_weekdaySummary • ${doctor.availableTime}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      '₹$formattedFee · ${doctor.experienceYears} yrs exp',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
