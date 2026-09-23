import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/appointments/domain/doctor.dart';
import 'package:sunil_medical_store/features/appointments/presentation/providers/appointment_providers.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/profile_providers.dart';

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

/// Confirms and books an appointment with [doctor] — shared by the
/// Appointments tab and the Doctors tab of the search screen so both use
/// the exact same confirm-dialog copy and booking flow.
Future<void> bookAppointment(BuildContext context, WidgetRef ref, Doctor doctor) async {
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
