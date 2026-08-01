import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/widgets/placeholder_screen.dart';
import 'package:sunil_medical_store/features/admin/presentation/widgets/admin_sign_out_button.dart';

/// Admin > Statistics tab. Placeholder until analytics dashboards are built.
class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Statistics',
      icon: Icons.bar_chart_outlined,
      message: 'Orders, appointments, inventory, and user analytics will be shown here.',
      appBarActions: [AdminSignOutButton()],
    );
  }
}
