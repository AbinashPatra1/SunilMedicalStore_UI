import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/models/prescription.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_prescription.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/status_chip.dart';

/// Admin's row-per-prescription: thumbnail + user + upload date + status.
/// Tap to review.
class AdminPrescriptionTile extends StatelessWidget {
  const AdminPrescriptionTile({super.key, required this.prescription, required this.onTap});

  final AdminPrescription prescription;
  final VoidCallback onTap;

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
                    Text(prescription.userName, style: theme.textTheme.titleSmall),
                    Text(
                      prescription.userPhone,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      DateFormat('EEE, d MMM yyyy • h:mm a').format(prescription.uploadedOn),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusChip(label: prescription.status.label, positive: positive),
            ],
          ),
        ),
      ),
    );
  }
}
