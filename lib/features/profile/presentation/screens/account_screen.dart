import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/profile/domain/customer_profile.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/profile_providers.dart';

/// Account screen: the customer's photo (by gender), editable personal
/// details, and medical records.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  static final _dateFormat = DateFormat('d MMM yyyy');
  static final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  Gender? _gender;
  DateTime? _dateOfBirth;
  bool _seeded = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _seedFrom(CustomerProfile profile) {
    if (_seeded) return;
    _seeded = true;
    _nameController.text = profile.fullName;
    _emailController.text = profile.email ?? '';
    _gender = profile.gender;
    _dateOfBirth = profile.dateOfBirth;
  }

  IconData _genderIcon(Gender? gender) => switch (gender) {
    Gender.male => Icons.man,
    Gender.female => Icons.woman,
    Gender.other => Icons.person,
    null => Icons.person_outline,
  };

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final email = _emailController.text.trim();
      await ref
          .read(profileRepositoryProvider)
          .upsertProfile(
            fullName: _nameController.text.trim(),
            email: email.isEmpty ? null : email,
            gender: _gender,
            dateOfBirth: _dateOfBirth,
          );
      ref.invalidate(customerProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(customerProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load account.')),
        data: (profile) {
          _seedFrom(profile);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(_genderIcon(_gender), size: 56, color: theme.colorScheme.onPrimaryContainer),
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
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          enabled: !_saving,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(labelText: 'Full name'),
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.length < 2 || !RegExp(r'[A-Za-z]').hasMatch(value)) {
                              return 'Enter a valid name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppConstants.spacingMd),
                        DropdownButtonFormField<Gender?>(
                          initialValue: _gender,
                          decoration: const InputDecoration(labelText: 'Gender'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Not set')),
                            for (final g in Gender.values) DropdownMenuItem(value: g, child: Text(g.label)),
                          ],
                          onChanged: _saving ? null : (v) => setState(() => _gender = v),
                        ),
                        const SizedBox(height: AppConstants.spacingMd),
                        InkWell(
                          onTap: _saving ? null : _pickDateOfBirth,
                          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date of birth',
                              suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                            ),
                            child: Text(
                              _dateOfBirth == null ? 'Not set' : _dateFormat.format(_dateOfBirth!),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingMd),
                        TextFormField(
                          controller: _emailController,
                          enabled: !_saving,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email ID'),
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isNotEmpty && !_emailPattern.hasMatch(value)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppConstants.spacingMd),
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Phone number',
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingSm),
                            Expanded(child: Text(profile.phoneNumber, style: theme.textTheme.bodyMedium)),
                            Icon(Icons.lock_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingLg),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Save changes'),
                          ),
                        ),
                      ],
                    ),
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
          );
        },
      ),
    );
  }
}
