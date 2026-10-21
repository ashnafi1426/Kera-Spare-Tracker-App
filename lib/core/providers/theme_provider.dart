import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';

/// Provider for LocalStorageService.
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return const LocalStorageService();
});

/// Initial theme mode loaded on application startup (defaults to ThemeMode.system).
final initialThemeModeProvider = Provider<ThemeMode>((ref) {
  return ThemeMode.system;
});

/// Controller managing the application theme mode (System, Light, Dark).
class ThemeModeController extends Notifier<ThemeMode> {
  late final LocalStorageService _storage;

  @override
  ThemeMode build() {
    _storage = ref.watch(localStorageServiceProvider);
    return ref.watch(initialThemeModeProvider);
  }

  /// Sets and persists the selected ThemeMode.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    final modeString = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _storage.saveThemeMode(modeString);
  }
}

/// Provider exposing the ThemeModeController.
final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
