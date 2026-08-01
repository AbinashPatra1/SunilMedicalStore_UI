import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/widgets/placeholder_screen.dart';
import 'package:sunil_medical_store/features/admin/presentation/widgets/admin_sign_out_button.dart';

/// Admin > Orders tab. Placeholder until order status management is built.
class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Orders',
      icon: Icons.receipt_long_outlined,
      message: 'All customer orders with status controls will be shown here.',
      appBarActions: [AdminSignOutButton()],
    );
  }
}
