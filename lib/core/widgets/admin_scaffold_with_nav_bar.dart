import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/widgets/app_bottom_nav_bar.dart';
import 'package:sunil_medical_store/core/widgets/refresh_on_focus.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/providers/admin_appointment_providers.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/providers/doctor_admin_providers.dart';
import 'package:sunil_medical_store/features/admin/inventory/presentation/providers/inventory_providers.dart';
import 'package:sunil_medical_store/features/admin/lab_tests/presentation/providers/lab_test_admin_providers.dart';
import 'package:sunil_medical_store/features/admin/orders/presentation/providers/admin_order_providers.dart';
import 'package:sunil_medical_store/features/admin/orders/presentation/providers/admin_prescription_providers.dart';
import 'package:sunil_medical_store/features/admin/pathology/presentation/providers/admin_lab_test_providers.dart';

/// App shell for the admin console: hosts the five bottom-navigation tabs.
///
/// The [navigationShell] is supplied by [StatefulShellRoute.indexedStack] in
/// `app_router.dart`; each tab keeps its own navigation stack and state.
/// Structurally identical to the customer `ScaffoldWithNavBar` but with an
/// admin-specific tab set + a Sign Out action in the app bar (admins have no
/// Profile tab to sign out from).
class AdminScaffoldWithNavBar extends ConsumerWidget {
  const AdminScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(WidgetRef ref, int index) {
    final switching = index != navigationShell.currentIndex;
    navigationShell.goBranch(index, initialLocation: !switching);
    // Tabs stay alive in the background, so refetch the one being shown.
    if (switching) {
      switch (index) {
        case 0:
          refreshIfIdle(ref, adminInventoryListProvider);
        case 1:
          refreshIfIdle(ref, adminAppointmentsProvider);
          refreshIfIdle(ref, adminDoctorsProvider);
        case 2:
          refreshIfIdle(ref, adminOrdersProvider);
          refreshIfIdle(ref, adminPrescriptionsProvider);
          refreshIfIdle(ref, adminLabTestBookingsProvider);
        case 3:
          refreshIfIdle(ref, adminLabTestsProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => _onTap(ref, i),
        destinations: const [
          AppNavDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          AppNavDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Appointments',
          ),
          AppNavDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          AppNavDestination(
            icon: Icon(Icons.biotech_outlined),
            selectedIcon: Icon(Icons.biotech),
            label: 'Lab Tests',
          ),
          AppNavDestination(
            icon: Icon(Icons.more_horiz_outlined),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
