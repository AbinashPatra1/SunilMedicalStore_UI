import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/profile/domain/past_appointment.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/profile_providers.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/status_chip.dart';

/// Profile > Appointments: the customer's past appointments plus a button to
/// book a new one (switches to the Appointments tab).
class ProfileAppointmentsScreen extends ConsumerWidget {
  const ProfileAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(pastAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: Column(
        children: [
          Expanded(
            child: appointmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(child: Text('Could not load appointments.')),
              data: (appointments) {
                if (appointments.isEmpty) {
                  return const Center(child: Text('No past appointments.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppConstants.spacingLg),
                  itemCount: appointments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingMd),
                  itemBuilder: (context, index) => _AppointmentCard(appointment: appointments[index]),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.appointments),
                  icon: const Icon(Icons.add),
                  label: const Text('Book Appointment'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final PastAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.medical_services_outlined, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appointment.doctorName, style: theme.textTheme.titleSmall),
                  Text(
                    appointment.specialization,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    DateFormat('d MMM yyyy, h:mm a').format(appointment.dateTime),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            StatusChip(
              label: appointment.status.label,
              positive: appointment.status == AppointmentStatus.completed,
            ),
          ],
        ),
      ),
    );
  }
}
