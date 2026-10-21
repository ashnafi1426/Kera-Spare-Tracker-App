import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/constants.dart';

/// State notifier managing the active application locale (defaults to Amharic).
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    return const Locale(AppConstants.defaultLocaleCode);
  }

  /// Changes the active locale.
  void setLocale(Locale newLocale) {
    state = newLocale;
  }

  /// Toggles between Amharic and English.
  void toggleLocale() {
    if (state.languageCode == AppConstants.defaultLocaleCode) {
      state = const Locale(AppConstants.englishLocaleCode);
    } else {
      state = const Locale(AppConstants.defaultLocaleCode);
    }
  }
}

/// Provider exposing the current application locale.
final localeNotifierProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
