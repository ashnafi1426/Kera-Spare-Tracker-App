import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/constants.dart';

/// Default shared instance of FlutterSecureStorage configured with safe error recovery on Android.
const defaultSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    resetOnError: true,
  ),
);

/// Local storage service for user preferences and persistent configuration.
class LocalStorageService {
  final FlutterSecureStorage _storage;

  const LocalStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? defaultSecureStorage;

  /// Retrieves the persisted language code ('am' or 'en'), or null if unset.
  Future<String?> getSavedLocaleCode() async {
    try {
      return await _storage
          .read(key: AppConstants.localePreferenceKey)
          .timeout(const Duration(milliseconds: 300), onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

  /// Persists the selected language code.
  Future<void> saveLocaleCode(String code) async {
    try {
      await _storage.write(key: AppConstants.localePreferenceKey, value: code);
    } catch (_) {
      // Ignored for resilience on restricted storage devices
    }
  }

  /// Retrieves the persisted theme mode ('system', 'light', 'dark'), or null if unset.
  Future<String?> getSavedThemeMode() async {
    try {
      return await _storage
          .read(key: AppConstants.themeModePreferenceKey)
          .timeout(const Duration(milliseconds: 300), onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

  /// Persists the selected theme mode.
  Future<void> saveThemeMode(String mode) async {
    try {
      await _storage.write(key: AppConstants.themeModePreferenceKey, value: mode);
    } catch (_) {
      // Ignored
    }
  }
}

