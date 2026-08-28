import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/models/prescription.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_prescription.dart';
import 'package:sunil_medical_store/features/admin/orders/presentation/providers/admin_prescription_providers.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/status_chip.dart';

/// Admin reviews a single prescription: full-size image + Approve/Reject.
/// Rejecting prompts for an optional note (shown to the customer).
class AdminPrescriptionDetailScreen extends ConsumerWidget {
  const AdminPrescriptionDetailScreen({super.key, required this.prescriptionId});

  final String prescriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPrescriptionByIdProvider(prescriptionId));
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Prescription')),
        body: Center(
          child: Text(error is ApiException ? error.message : 'Could not load prescription.'),
        ),
      ),
      data: (prescription) => _ReviewView(prescription: prescription),
    );
  }
}

class _ReviewView extends ConsumerStatefulWidget {
  const _ReviewView({required this.prescription});

  final AdminPrescription prescription;

  @override
  ConsumerState<_ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends ConsumerState<_ReviewView> {
  bool _saving = false;
  String? _error;

  Future<void> _approve() => _review(PrescriptionStatus.approved);

  Future<void> _reject() async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reject prescription?'),
        content: TextField(
          controller: noteController,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            hintText: 'Shown to the customer',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(dialogCtx).colorScheme.onErrorContainer,
              backgroundColor: Theme.of(dialogCtx).colorScheme.errorContainer,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _review(PrescriptionStatus.rejected, note: noteController.text.trim());
  }

  Future<void> _review(PrescriptionStatus status, {String? note}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(adminPrescriptionRepositoryProvider).review(
        widget.prescription.id,
        status: status,
        note: note?.isEmpty ?? true ? null : note,
      );
      ref.invalidate(adminPrescriptionByIdProvider(widget.prescription.id));
      ref.invalidate(adminPrescriptionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(status == PrescriptionStatus.approved ? 'Prescription approved' : 'Prescription rejected'),
          ));
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.prescription;
    final positive = p.status != PrescriptionStatus.rejected;
    final pending = p.status == PrescriptionStatus.pending;

    return Scaffold(
      appBar: AppBar(title: const Text('Review prescription')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.userName, style: theme.textTheme.titleSmall),
                  Text(
                    p.userPhone,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  Text(
                    'Uploaded ${DateFormat('EEE, d MMM yyyy • h:mm a').format(p.uploadedOn)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  StatusChip(label: p.status.label, positive: positive),
                  if (p.note != null) ...[
                    const SizedBox(height: AppConstants.spacingSm),
                    Text('Note: ${p.note}', style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            child: Image.network(
              p.imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const Center(child: Padding(
                    padding: EdgeInsets.all(AppConstants.spacingXl),
                    child: CircularProgressIndicator(),
                  )),
              errorBuilder: (_, _, _) => Container(
                height: 200,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.onSurfaceVariant, size: 48),
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppConstants.spacingMd),
            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
          ],
          if (pending) ...[
            const SizedBox(height: AppConstants.spacingLg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _reject,
                    style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _approve,
                    icon: _saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
