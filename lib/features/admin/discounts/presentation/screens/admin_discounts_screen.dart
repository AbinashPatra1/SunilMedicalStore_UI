import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/widgets/placeholder_screen.dart';
import 'package:sunil_medical_store/features/admin/presentation/widgets/admin_sign_out_button.dart';

/// Admin > Discounts tab. Placeholder until promo-code management is built.
class AdminDiscountsScreen extends StatelessWidget {
  const AdminDiscountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Discounts',
      icon: Icons.local_offer_outlined,
      message: 'Promo codes and eligibility rules will be managed here.',
      appBarActions: [AdminSignOutButton()],
    );
  }
}
