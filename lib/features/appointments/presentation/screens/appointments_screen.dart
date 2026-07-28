import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/utils/week_range.dart';
import 'package:sunil_medical_store/features/appointments/domain/doctor.dart';
import 'package:sunil_medical_store/features/appointments/presentation/providers/appointment_providers.dart';
import 'package:sunil_medical_store/features/appointments/presentation/widgets/doctor_card.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/profile_providers.dart';

/// Appointments tab: doctors available in the current week.
class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  /// The nearest date (today or later, within 2 weeks) matching one of the
  /// doctor's recurring [weekdays].
  DateTime _nextAvailableDate(List<int> weekdays) {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    for (var i = 0; i < 14; i++) {
      final candidate = todayDateOnly.add(Duration(days: i));
      if (weekdays.contains(candidate.weekday)) return candidate;
    }
    return todayDateOnly;
  }

  Future<void> _book(BuildContext context, WidgetRef ref, Doctor doctor) async {
    final date = _nextAvailableDate(doctor.availableWeekdays);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm appointment'),
        content: Text(
          'Book with ${doctor.name} on ${DateFormat('EEEE, d MMM').format(date)} '
          'at ${doctor.availableTime}?\n\nConsultation fee: ₹${doctor.consultationFee}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Booking appointment…')));

    try {
      await ref.read(appointmentRepositoryProvider).book(
        doctorId: doctor.id,
        date: date,
        timeSlot: doctor.availableTime,
      );
      // Refresh Profile > Appointments so the new booking shows up there.
      ref.invalidate(pastAppointmentsProvider);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Appointment booked with ${doctor.name}!')));
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

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
              onBook: () => _book(context, ref, doctor),
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
