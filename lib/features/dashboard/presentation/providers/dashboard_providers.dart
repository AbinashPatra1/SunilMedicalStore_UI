import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A storefront category shown on the dashboard landing page.
class HomeCategory {
  const HomeCategory({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Dummy category list for the landing page.
///
/// This provider stands in for a repository. When the real catalog exists,
/// replace the hard-coded list here with a fetch from the backend — the
/// dashboard UI reading this provider won't need to change.
final homeCategoriesProvider = Provider<List<HomeCategory>>((ref) {
  return const [
    HomeCategory(label: 'Medicines', icon: Icons.medication_outlined),
    HomeCategory(label: 'Wellness', icon: Icons.spa_outlined),
    HomeCategory(label: 'Personal Care', icon: Icons.face_retouching_natural),
    HomeCategory(label: 'Devices', icon: Icons.monitor_heart_outlined),
    HomeCategory(label: 'Baby Care', icon: Icons.child_friendly_outlined),
    HomeCategory(label: 'Ayurveda', icon: Icons.eco_outlined),
  ];
});
