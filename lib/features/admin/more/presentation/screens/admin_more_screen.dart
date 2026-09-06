import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/presentation/widgets/admin_sign_out_button.dart';

/// Admin > More: catch-all menu tab for admin destinations that don't
/// warrant their own bottom-nav slot. Currently Statistics and Users;
/// future admin-only screens append here the same way.
class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        actions: const [AdminSignOutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
        children: [
          _MoreMenuTile(
            icon: Icons.bar_chart_outlined,
            title: 'Statistics',
            subtitle: 'Revenue, orders, appointments, lab tests',
            onTap: () => context.push('${AppRoutes.adminMore}/statistics'),
          ),
          _MoreMenuTile(
            icon: Icons.people_outline,
            title: 'Users',
            subtitle: 'Browse, add, edit and remove customers',
            onTap: () => context.push(AppRoutes.adminUsers),
          ),
        ],
      ),
    );
  }
}

class _MoreMenuTile extends StatelessWidget {
  const _MoreMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
