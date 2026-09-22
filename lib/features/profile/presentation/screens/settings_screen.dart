import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/widgets/app_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/theme_controller.dart';

/// Profile > Settings: app-wide preferences. Currently just the dark-mode
/// toggle; future preferences append here the same way.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark mode'),
              subtitle: const Text('Use a dark color scheme'),
              value: themeMode == ThemeMode.dark,
              onChanged: (v) =>
                  ref.read(themeModeProvider.notifier).setDarkMode(v),
            ),
          ),
        ],
      ),
    );
  }
}
