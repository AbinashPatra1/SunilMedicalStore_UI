import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _themeModeStorageKey = 'theme_mode';

/// The app's current [ThemeMode]. Defaults to light (not the device/system
/// setting) — persisted via `flutter_secure_storage` once the user picks a
/// mode in Profile > Settings, so the choice survives app restarts.
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  static const _storage = FlutterSecureStorage();

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.light;
  }

  Future<void> _load() async {
    final saved = await _storage.read(key: _themeModeStorageKey);
    if (saved == 'dark') state = ThemeMode.dark;
  }

  Future<void> setDarkMode(bool enabled) async {
    state = enabled ? ThemeMode.dark : ThemeMode.light;
    await _storage.write(key: _themeModeStorageKey, value: enabled ? 'dark' : 'light');
  }
}
