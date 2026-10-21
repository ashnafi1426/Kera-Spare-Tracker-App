import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/constants.dart';

/// Local storage service for user preferences and persistent configuration.
class LocalStorageService {
  final FlutterSecureStorage _storage;

  const LocalStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Retrieves the persisted language code ('am' or 'en'), or null if unset.
  Future<String?> getSavedLocaleCode() async {
    try {
      return await _storage.read(key: AppConstants.localePreferenceKey);
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
}
