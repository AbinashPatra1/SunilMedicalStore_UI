import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/prescriptions/presentation/providers/prescription_providers.dart';
import 'package:sunil_medical_store/features/prescriptions/presentation/widgets/prescription_tile.dart';
import 'package:sunil_medical_store/core/widgets/refresh_on_focus.dart';
import 'package:sunil_medical_store/core/paging/paged_widgets.dart';

/// Pharmacy > Prescription: the customer's uploaded prescriptions, with an
/// upload action (camera or gallery). Reused from checkout when an
/// Rx-flagged item needs one attached.
class PrescriptionsScreen extends ConsumerStatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  ConsumerState<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends ConsumerState<PrescriptionsScreen> {
  bool _uploading = false;

  Future<void> _pickAndUpload(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      await ref.read(prescriptionRepositoryProvider).upload(File(picked.path));
      ref.invalidate(prescriptionsProvider);
      ref.invalidate(pagedPrescriptionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Prescription uploaded — pending review')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openSourcePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pickAndUpload(source);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(pagedPrescriptionsProvider);

    return RefreshOnFocus(
      onRefresh: () { refreshIfIdle(ref, pagedPrescriptionsProvider); },
      child: Scaffold(
      appBar: AppBar(title: const Text('Prescriptions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _openSourcePicker,
        icon: _uploading
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.upload_outlined),
        label: Text(_uploading ? 'Uploading…' : 'Upload prescription'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error is ApiException ? error.message : 'Could not load prescriptions.'),
              const SizedBox(height: AppConstants.spacingSm),
              TextButton(
                onPressed: () => ref.invalidate(pagedPrescriptionsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (paged) {
          final prescriptions = paged.items;
          if (prescriptions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.description_outlined, size: 56, color: theme.colorScheme.primary),
                    const SizedBox(height: AppConstants.spacingMd),
                    Text('No prescriptions yet', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      'Upload one with the button below.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pagedPrescriptionsProvider),
            child: InfiniteListView(
              state: paged,
              onLoadMore: () => ref.read(pagedPrescriptionsProvider.notifier).loadMore(),
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingLg,
                AppConstants.spacingSm,
                AppConstants.spacingLg,
                AppConstants.spacingXxl + AppConstants.spacingLg,
              ),
              separatorHeight: AppConstants.spacingSm,
              itemBuilder: (context, prescription) => PrescriptionTile(prescription: prescription),
            ),
          );
        },
      ),
    ),
    );
  }
}
