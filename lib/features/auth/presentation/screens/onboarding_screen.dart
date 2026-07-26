import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_controller.dart';

/// Shown to a newly verified user who has no name yet. Captures the full name,
/// which is saved onto the Firebase user before entering the app.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).completeOnboarding(_nameController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.waving_hand_outlined, size: 56, color: theme.colorScheme.primary),
                  const SizedBox(height: AppConstants.spacingMd),
                  Text('Welcome!', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    "Let's set up your profile. What should we call you?",
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacingXl),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    enabled: !auth.isSubmitting,
                    onFieldSubmitted: (_) => _continue(),
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => (value == null || value.trim().length < 2)
                        ? 'Please enter your name'
                        : null,
                  ),
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: AppConstants.spacingMd),
                    Text(
                      auth.errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppConstants.spacingLg),
                  ElevatedButton(
                    onPressed: auth.isSubmitting ? null : _continue,
                    child: auth.isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Continue'),
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  TextButton(
                    onPressed: auth.isSubmitting
                        ? null
                        : () => ref.read(authControllerProvider.notifier).signOut(),
                    child: const Text('Not you? Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
