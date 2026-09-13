import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/illustrations/search_empty_illustration.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/appointments/presentation/providers/appointment_providers.dart';
import 'package:sunil_medical_store/features/profile/domain/past_appointment.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/profile_providers.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/star_rating.dart';
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
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error is ApiException ? error.message : 'Could not load appointments.'),
                    const SizedBox(height: AppConstants.spacingSm),
                    TextButton(
                      onPressed: () => ref.invalidate(pastAppointmentsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (appointments) {
                if (appointments.isEmpty) {
                  final theme = Theme.of(context);
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingXl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SearchEmptyIllustration(size: 96),
                          const SizedBox(height: AppConstants.spacingMd),
                          Text(
                            'No past appointments.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(pastAppointmentsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppConstants.spacingLg),
                    itemCount: appointments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingMd),
                    itemBuilder: (context, index) => _AppointmentCard(appointment: appointments[index]),
                  ),
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

class _AppointmentCard extends ConsumerStatefulWidget {
  const _AppointmentCard({required this.appointment});

  final PastAppointment appointment;

  @override
  ConsumerState<_AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends ConsumerState<_AppointmentCard> {
  bool _cancelling = false;
  bool _rating = false;

  Future<void> _cancel() async {
    final appointment = widget.appointment;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: Text(
          'This will cancel your appointment with ${appointment.doctorName}. This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep appointment'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await ref.read(appointmentRepositoryProvider).cancel(appointment.id);
      ref.invalidate(pastAppointmentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Appointment cancelled')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _rateDoctor() async {
    final appointment = widget.appointment;
    var selected = 0;
    final stars = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Rate ${appointment.doctorName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your appointment?'),
              const SizedBox(height: AppConstants.spacingMd),
              StarRating(
                value: selected,
                size: 36,
                onChanged: (v) => setDialogState(() => selected = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected == 0 ? null : () => Navigator.of(dialogContext).pop(selected),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
    if (stars == null || !mounted) return;

    setState(() => _rating = true);
    try {
      await ref.read(appointmentRepositoryProvider).rate(appointment.id, stars);
      ref.invalidate(pastAppointmentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Thanks for rating!')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _rating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appointment = widget.appointment;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                      if (appointment.appointmentNumber != null)
                        Text(
                          appointment.appointmentNumber!,
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
                  positive: appointment.status != AppointmentStatus.cancelled,
                ),
              ],
            ),
            if (appointment.status.isCustomerCancellable) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _cancelling ? null : _cancel,
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  icon: _cancelling
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel'),
                ),
              ),
            ] else if (appointment.status == AppointmentStatus.completed) ...[
              const SizedBox(height: AppConstants.spacingSm),
              if (appointment.myRating != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Your rating: ',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    StarRating(value: appointment.myRating!, size: 16),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _rating ? null : _rateDoctor,
                    icon: _rating
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.star_outline, size: 18),
                    label: const Text('Rate doctor'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
