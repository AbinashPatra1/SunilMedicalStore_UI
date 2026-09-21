import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/theme/app_palette.dart';

/// A single tappable row in the profile options list, with its icon on a
/// pastel rounded tile in the row's own [accent] colour.
class ProfileOptionTile extends StatelessWidget {
  const ProfileOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = AppAccent.mint,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppAccent accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: accent.pastel, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: accent.ink, size: 22),
        ),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
