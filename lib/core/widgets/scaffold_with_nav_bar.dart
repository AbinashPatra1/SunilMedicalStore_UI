import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/widgets/app_bottom_nav_bar.dart';
import 'package:sunil_medical_store/core/widgets/refresh_on_focus.dart';
import 'package:sunil_medical_store/features/appointments/presentation/providers/appointment_providers.dart';
import 'package:sunil_medical_store/features/lab_tests/presentation/providers/lab_test_providers.dart';
import 'package:sunil_medical_store/features/medicines/presentation/providers/medicine_providers.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/profile_providers.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/cart_providers.dart';

/// App shell for the customer area: hosts the four bottom-navigation tabs.
///
/// The [navigationShell] is supplied by [StatefulShellRoute.indexedStack] in
/// `app_router.dart`; each tab keeps its own navigation stack and state.
class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(WidgetRef ref, int index) {
    final switching = index != navigationShell.currentIndex;
    // Navigate to the branch. Re-tapping the active tab pops it to its root.
    navigationShell.goBranch(index, initialLocation: !switching);
    // Tabs stay alive in the background, so refetch the one being shown.
    if (switching) {
      switch (index) {
        case 0:
          refreshIfIdle(ref, suggestedProductsProvider);
        case 1:
          refreshIfIdle(ref, labTestCatalogProvider);
        case 2:
          refreshIfIdle(ref, weeklyDoctorsProvider);
        case 4:
          refreshIfIdle(ref, customerProfileProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => _onTap(ref, i),
        destinations: [
          const AppNavDestination(
            icon: Icon(Icons.local_pharmacy_outlined),
            selectedIcon: Icon(Icons.local_pharmacy),
            label: 'Pharmacy',
          ),
          const AppNavDestination(
            icon: Icon(Icons.biotech_outlined),
            selectedIcon: Icon(Icons.biotech),
            label: 'Lab Tests',
          ),
          const AppNavDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Appointments',
          ),
          AppNavDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          const AppNavDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
