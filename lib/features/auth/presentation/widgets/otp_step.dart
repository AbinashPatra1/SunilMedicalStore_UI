import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';

/// Second step of sign-in: enter the 6-digit OTP sent to [phoneNumber].
class OtpStep extends StatelessWidget {
  const OtpStep({
    super.key,
    required this.formKey,
    required this.controller,
    required this.phoneNumber,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onVerify,
    required this.onChangeNumber,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final String phoneNumber;
  final bool isSubmitting;
  final String? errorMessage;
  final VoidCallback onVerify;
  final VoidCallback onChangeNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter the OTP sent to +91 $phoneNumber',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingLg),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            enabled: !isSubmitting,
            maxLength: 6,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onVerify(),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'OTP',
              prefixIcon: Icon(Icons.sms_outlined),
              counterText: '',
            ),
            validator: (value) => (value == null || value.length != 6)
                ? 'Enter the 6-digit OTP'
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
            onPressed: isSubmitting ? null : onVerify,
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verify & Sign In'),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          TextButton(
            onPressed: isSubmitting ? null : onChangeNumber,
            child: const Text('Change number'),
          ),
        ],
      ),
    );
  }
}
