import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_controller.dart';
import 'package:sunil_medical_store/features/auth/presentation/widgets/otp_step.dart';
import 'package:sunil_medical_store/features/auth/presentation/widgets/phone_step.dart';

/// Phone-number + OTP sign-in.
///
/// A [ConsumerStatefulWidget] because the two steps own their
/// [TextEditingController]s and the current step is local UI state. All auth
/// logic lives in [AuthController]; navigation on success is handled by the
/// router's redirect, not here.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

enum _Step { phone, otp }

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  _Step _step = _Step.phone;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final sent = await ref.read(authControllerProvider.notifier).sendOtp(
      _phoneController.text,
    );
    if (sent && mounted) setState(() => _step = _Step.otp);
  }

  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).verifyOtp(_otpController.text);
  }

  void _changeNumber() {
    _otpController.clear();
    ref.read(authControllerProvider.notifier).resetOtp();
    setState(() => _step = _Step.phone);
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.local_pharmacy_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppConstants.spacingMd),
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingXs),
                Text(
                  _step == _Step.phone
                      ? 'Sign in with your mobile number'
                      : 'Verify your number',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingXl),
                if (_step == _Step.phone)
                  PhoneStep(
                    formKey: _phoneFormKey,
                    controller: _phoneController,
                    isSubmitting: auth.isSubmitting,
                    errorMessage: auth.errorMessage,
                    onSubmit: _sendOtp,
                  )
                else
                  OtpStep(
                    formKey: _otpFormKey,
                    controller: _otpController,
                    phoneNumber: _phoneController.text.trim(),
                    isSubmitting: auth.isSubmitting,
                    errorMessage: auth.errorMessage,
                    onVerify: _verifyOtp,
                    onChangeNumber: _changeNumber,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
