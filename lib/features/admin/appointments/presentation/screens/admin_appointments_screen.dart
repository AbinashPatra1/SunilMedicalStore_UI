import 'package:flutter/material.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/screens/admin_appointments_list_screen.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/screens/admin_doctors_list_screen.dart';
import 'package:sunil_medical_store/features/admin/presentation/widgets/admin_sign_out_button.dart';

/// Admin > Appointments tab: hosts two sub-tabs — Appointments (all bookings
/// across users) and Doctors (schedule management). Each sub-tab is a full
/// screen; a Material [TabBar] switches between them.
class AdminAppointmentsScreen extends StatelessWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: _TabAppBar(),
        body: TabBarView(
          children: [
            AdminAppointmentsListScreen(),
            AdminDoctorsListScreen(),
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
      title: const Text('Appointments'),
      actions: const [AdminSignOutButton()],
      bottom: const TabBar(
        tabs: [
          Tab(text: 'Appointments'),
          Tab(text: 'Doctors'),
        ],
      ),
    );
  }
}
