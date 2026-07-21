import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/widgets/placeholder_screen.dart';

/// Login screen. Will host the email/password + phone OTP sign-in flow
/// backed by Firebase Authentication.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Login',
      icon: Icons.lock_outline,
      message: 'Firebase Authentication sign-in will be implemented here.',
    );
  }
}
