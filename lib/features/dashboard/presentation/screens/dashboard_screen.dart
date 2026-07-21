import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/widgets/placeholder_screen.dart';

/// Post-login home screen: categories, offers, and quick access to
/// medicines, cart, and orders.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      message: 'Store overview and quick actions will be implemented here.',
    );
  }
}
