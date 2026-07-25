import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';

/// First step of sign-in: enter a 10-digit Indian mobile number.
class PhoneStep extends StatelessWidget {
  const PhoneStep({
    super.key,
    required this.formKey,
    required this.controller,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool isSubmitting;
  final String? errorMessage;
  final VoidCallback onSubmit;

  static final _indianMobile = RegExp(r'^[6-9]\d{9}$');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            enabled: !isSubmitting,
            maxLength: 10,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Mobile number',
              prefixText: '+91  ',
              prefixIcon: Icon(Icons.phone_android_outlined),
              counterText: '',
            ),
            validator: (value) => (value == null || !_indianMobile.hasMatch(value))
                ? 'Enter a valid 10-digit mobile number'
                : null,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppConstants.spacingLg),
          ElevatedButton(
            onPressed: isSubmitting ? null : onSubmit,
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send OTP'),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'Demo: number 9999999999 signs in as admin; any other valid '
            'number is a customer.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
