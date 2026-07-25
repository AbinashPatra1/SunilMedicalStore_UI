import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';

/// The two quick-entry buttons above the search bar: search medicines by an
/// image, and upload a prescription.
class PharmacyActionButtons extends StatelessWidget {
  const PharmacyActionButtons({
    super.key,
    required this.onSearchByImage,
    required this.onUploadPrescription,
  });

  final VoidCallback onSearchByImage;
  final VoidCallback onUploadPrescription;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSearchByImage,
            icon: const Icon(Icons.center_focus_strong_outlined),
            label: const Text('Search by image'),
          ),
        ),
        const SizedBox(width: AppConstants.spacingMd),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onUploadPrescription,
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Prescription'),
          ),
        ),
      ],
    );
  }
}
