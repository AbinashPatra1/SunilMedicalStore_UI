import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/pathology/domain/admin_lab_test_booking.dart';
import 'package:sunil_medical_store/features/admin/pathology/presentation/providers/admin_lab_test_providers.dart';
import 'package:sunil_medical_store/features/admin/presentation/widgets/status_swipe_bar.dart';
import 'package:sunil_medical_store/features/profile/domain/lab_test.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/status_chip.dart';

/// Admin views a lab-test booking and can advance its status
/// (`scheduled → inSession → completed`) or cancel it.
class AdminLabTestBookingDetailScreen extends ConsumerWidget {
  const AdminLabTestBookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminLabTestBookingByIdProvider(bookingId));
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Lab Test')),
        body: Center(
          child: Text(error is ApiException ? error.message : 'Could not load booking.'),
        ),
      ),
      data: (booking) => _DetailForm(existing: booking),
    );
  }
}

class _DetailForm extends ConsumerStatefulWidget {
  const _DetailForm({required this.existing});

  final AdminLabTestBooking existing;

  @override
  ConsumerState<_DetailForm> createState() => _DetailFormState();
}

class _DetailFormState extends ConsumerState<_DetailForm> {
  late AdminLabTestBooking _booking = widget.existing;
  bool _busy = false;
  String? _error;

  Future<void> _advance() async {
    final next = _booking.status.next;
    if (next == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await ref.read(adminLabTestRepositoryProvider).updateStatus(_booking.id, next);
      ref.invalidate(adminLabTestBookingsProvider);
      if (mounted) {
        setState(() => _booking = updated);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Booking marked ${next.label}')));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text('This will cancel ${_booking.name} for ${_booking.userName}. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep booking'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.onErrorContainer,
              backgroundColor: Theme.of(dialogContext).colorScheme.errorContainer,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(adminLabTestRepositoryProvider)
          .updateStatus(_booking.id, LabTestStatus.cancelled);
      ref.invalidate(adminLabTestBookingsProvider);
      if (mounted) {
        setState(() => _booking = updated);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Booking cancelled')));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = _booking;
    final advanceLabel = b.status.advanceLabel;

    return Scaffold(
      appBar: AppBar(title: Text(b.name)),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (b.bookingNumber != null)
                    Text(
                      b.bookingNumber!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  Text(b.userName, style: theme.textTheme.titleSmall),
                  Text(
                    b.userPhone,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  Text(
                    'Scheduled for ${DateFormat('EEE, d MMM yyyy').format(b.bookedOn)}'
                    '${b.timeSlot != null ? ' • ${b.timeSlot}' : ''}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(b.labName, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Parameters', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spacingSm),
          Card(
            child: Column(
              children: [
                for (final parameter in b.parameters)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
                    title: Text(parameter),
                  ),
                const Divider(height: 1),
                ListTile(
                  title: Text('Amount', style: theme.textTheme.titleMedium),
                  trailing: Text('₹${b.amount}', style: theme.textTheme.titleMedium),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Row(
            children: [
              Text('Status', style: theme.textTheme.titleMedium),
              const SizedBox(width: AppConstants.spacingSm),
              StatusChip(label: b.status.label, positive: b.status != LabTestStatus.cancelled),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          if (advanceLabel != null)
            StatusSwipeBar(
              label: advanceLabel,
              enabled: !_busy,
              onConfirm: _advance,
            ),
          if (_error != null) ...[
            const SizedBox(height: AppConstants.spacingMd),
            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: AppConstants.spacingLg),
          OutlinedButton.icon(
            onPressed: (_busy || b.status == LabTestStatus.cancelled) ? null : _cancel,
            style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel booking'),
          ),
        ],
      ),
    );
  }
}
