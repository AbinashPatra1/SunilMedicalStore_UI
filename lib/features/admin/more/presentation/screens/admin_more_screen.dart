import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_palette.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/presentation/widgets/admin_sign_out_button.dart';

/// Admin > More: catch-all menu tab for admin destinations that don't
/// warrant their own bottom-nav slot. Future admin-only screens append here
/// the same way.
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
            icon: Icons.notifications_none,
            title: 'Notifications',
            subtitle: 'New orders, bookings and appointments',
            onTap: () => context.push(AppRoutes.adminNotifications),
          ),
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
          _MoreMenuTile(
            icon: Icons.local_shipping_outlined,
            title: 'Delivery Settings',
            subtitle: 'Store location and pharmacy delivery radius',
            onTap: () => context.push('${AppRoutes.adminMore}/delivery-settings'),
          ),
          _MoreMenuTile(
            icon: Icons.view_carousel_outlined,
            title: 'Home Banners',
            subtitle: 'Configure the offers shown on the customer home screen',
            onTap: () => context.push(AppRoutes.adminBanners),
          ),
          _MoreMenuTile(
            icon: Icons.local_offer_outlined,
            title: 'Discounts',
            subtitle: 'Promo codes and offers',
            onTap: () => context.push(AppRoutes.adminDiscounts),
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
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppAccent.forSeed(title).pastel,
        child: Icon(icon, color: AppAccent.forSeed(title).ink),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
