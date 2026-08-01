import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/widgets/placeholder_screen.dart';
import 'package:sunil_medical_store/features/admin/presentation/widgets/admin_sign_out_button.dart';

/// Admin > Appointments tab. Placeholder until doctor-schedule + booking
/// management is built.
class AdminAppointmentsScreen extends StatelessWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Appointments',
      icon: Icons.calendar_month_outlined,
      message: 'Doctor schedules and user appointments will be managed here.',
      appBarActions: [AdminSignOutButton()],
    );
  }
}
