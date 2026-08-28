import 'package:flutter/material.dart';
import 'package:sunil_medical_store/features/admin/orders/presentation/screens/admin_orders_list_screen.dart';
import 'package:sunil_medical_store/features/admin/orders/presentation/screens/admin_prescriptions_list_screen.dart';
import 'package:sunil_medical_store/features/admin/presentation/widgets/admin_sign_out_button.dart';

/// Admin > Orders tab: hosts two sub-tabs — Orders (every order across
/// users) and Prescriptions (Rx review queue). Each sub-tab is a full
/// screen; a Material [TabBar] switches between them.
class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: _TabAppBar(),
        body: TabBarView(
          children: [
            AdminOrdersListScreen(),
            AdminPrescriptionsListScreen(),
          ],
        ),
      ),
    );
  }
}

class _TabAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _TabAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Orders'),
      actions: const [AdminSignOutButton()],
      bottom: const TabBar(
        tabs: [
          Tab(text: 'Orders'),
          Tab(text: 'Prescriptions'),
        ],
      ),
    );
  }
}
