import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/widgets/placeholder_screen.dart';

/// Shopping cart: line items, quantity adjustment, and checkout entry
/// point (including prescription upload for restricted medicines).
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Cart',
      icon: Icons.shopping_cart_outlined,
      message: 'Cart items and checkout will be implemented here.',
    );
  }
}
