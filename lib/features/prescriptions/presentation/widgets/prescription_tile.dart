import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/models/prescription.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/status_chip.dart';

/// A single uploaded prescription: thumbnail + upload date + review status
/// (and the admin's note, if rejected).
class PrescriptionTile extends StatelessWidget {
  const PrescriptionTile({super.key, required this.prescription, this.onTap});

  final Prescription prescription;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = prescription.status != PrescriptionStatus.rejected;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                child: Image.network(
                  prescription.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 56,
                    height: 56,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.description_outlined, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('d MMM yyyy, h:mm a').format(prescription.uploadedOn),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    StatusChip(label: prescription.status.label, positive: positive),
                    if (prescription.status == PrescriptionStatus.rejected &&
                        prescription.note != null) ...[
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        prescription.note!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
