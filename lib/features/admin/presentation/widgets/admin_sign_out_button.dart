import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_controller.dart';

/// App-bar sign-out button used by every admin screen — admins have no
/// Profile tab to sign out from, so it lives in each screen's app bar.
class AdminSignOutButton extends ConsumerWidget {
  const AdminSignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Sign out',
      icon: const Icon(Icons.logout),
      onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
    );
  }
}
