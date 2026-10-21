import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/constants.dart';
import '../services/storage_service.dart';

/// Provider for local storage service instance.
final storageServiceProvider = Provider<LocalStorageService>((ref) {
  return const LocalStorageService();
});

/// Initial locale code loaded at application boot, defaults to Amharic ('am').
final initialLocaleCodeProvider = Provider<String>((ref) {
  return AppConstants.defaultLocaleCode;
});

/// Controller managing application locale, persisting choices locally and updating UI live.
class LocaleController extends Notifier<Locale> {
  LocalStorageService get _storage => ref.read(storageServiceProvider);

  @override
  Locale build() {
    final initialCode = ref.watch(initialLocaleCodeProvider);
    return Locale(initialCode);
  }

  /// Sets the application locale immediately and persists it.
  Future<void> setLocale(Locale newLocale) async {
    if (state == newLocale) return;
    state = newLocale;
    await _storage.saveLocaleCode(newLocale.languageCode);
  }

  /// Toggles between Amharic and English.
  Future<void> toggleLocale() async {
    if (state.languageCode == AppConstants.defaultLocaleCode) {
      await setLocale(const Locale(AppConstants.englishLocaleCode));
    } else {
      await setLocale(const Locale(AppConstants.defaultLocaleCode));
    }
  }
}

/// Provider exposing the LocaleController.
final localeControllerProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);

/// Backward-compatible alias for localeControllerProvider.
final localeNotifierProvider = localeControllerProvider;
