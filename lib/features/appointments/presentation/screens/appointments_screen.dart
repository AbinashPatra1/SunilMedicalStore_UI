import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/utils/week_range.dart';
import 'package:sunil_medical_store/features/appointments/presentation/providers/appointment_providers.dart';
import 'package:sunil_medical_store/features/appointments/presentation/widgets/doctor_card.dart';

/// Appointments tab: doctors available in the current week.
class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final week = WeekRange.of(DateTime.now());
    final doctorsAsync = ref.watch(weeklyDoctorsProvider);

    final range =
        '${DateFormat('d MMM').format(week.start)} – ${DateFormat('d MMM').format(week.end)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: doctorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          onRetry: () => ref.invalidate(weeklyDoctorsProvider),
        ),
        data: (doctors) => ListView.separated(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          itemCount: doctors.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingMd),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available this week', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    range,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }
            final doctor = doctors[index - 1];
            return DoctorCard(
              doctor: doctor,
              week: week,
              onBook: () {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('Booking with ${doctor.name} coming soon'),
                    ),
                  );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Could not load doctors.'),
          const SizedBox(height: AppConstants.spacingSm),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
