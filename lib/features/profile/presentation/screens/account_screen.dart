import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/profile/domain/customer_profile.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/profile_providers.dart';

/// Account screen: the customer's photo (by gender), personal details, and
/// medical records.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  IconData _genderIcon(Gender? gender) => switch (gender) {
    Gender.male => Icons.man,
    Gender.female => Icons.woman,
    Gender.other => Icons.person,
    null => Icons.person_outline,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(customerProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load account.')),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(_genderIcon(profile.gender), size: 56, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  Text(profile.fullName, style: theme.textTheme.titleLarge),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingXl),
            Text('Personal details', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingSm),
            Card(
              child: Column(
                children: [
                  _DetailRow(label: 'Full Name', value: profile.fullName),
                  _DetailRow(label: 'Gender', value: profile.gender?.label ?? 'Not set'),
                  _DetailRow(
                    label: 'Date of birth',
                    value: profile.dateOfBirth == null
                        ? 'Not set'
                        : DateFormat('d MMM yyyy').format(profile.dateOfBirth!),
                  ),
                  _DetailRow(label: 'Phone number', value: profile.phoneNumber),
                  _DetailRow(label: 'Email ID', value: profile.email ?? 'Not set', isLast: true),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Text('Medical records', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingSm),
            if (profile.medicalRecords.isEmpty)
              Text(
                'No medical records yet.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            else
              Card(
                child: Column(
                  children: [
                    for (final record in profile.medicalRecords)
                      ListTile(
                        leading: Icon(Icons.description_outlined, color: theme.colorScheme.primary),
                        title: Text(record.title),
                        subtitle: Text('${record.type} • ${DateFormat('d MMM yyyy').format(record.date)}'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.isLast = false});

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}
