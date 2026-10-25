import 'package:flutter/foundation.dart';

/// Application-wide constants for Kera Spare Tracker.
class AppConstants {

  AppConstants._();

  /// Application name.
  static const String appName = 'Kera Spare Tracker';

  /// Supported language codes.
  static const String defaultLocaleCode = 'am'; // Amharic by default
  static const String englishLocaleCode = 'en';

  /// Application version
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  /// Support contacts (fallbacks)
  static const String fallbackSupportPhone = '+251911000000';
  static const String fallbackSupportTelegram = '@KeraSpareSupport';

  /// Default configurable brands for spare parts.
  static const List<String> defaultBrands = [
    'CAT',
    'Doosan',
    'Develon',
    'CTP',
    'IPD',
    'Hitachi',
    'SANY',
  ];

  /// Default shelf options for storage location.
  static const List<String> defaultShelves = [
    'Shelf 1',
    'Shelf 2',
    'Shelf 3',
    'Shelf 4',
    'Shelf 5',
    'Shelf 6',
  ];

  /// Common category suggestions for heavy machinery and automotive parts.
  static const List<String> defaultCategories = [
    'Engine',
    'Hydraulic',
    'Transmission',
    'Electrical',
    'Undercarriage',
    'Filters',
    'Seals & Gaskets',
    'Hardware & Fasteners',
    'Body & Cabin',
  ];

  /// Standard units of measurement.
  static const List<String> defaultUnits = [
    'Pcs',
    'Set',
    'Box',
    'Pair',
    'Meter',
    'Kg',
    'Liter',
  ];

  /// Local storage and secure storage keys.
  static const String secureStorageTokenKey = 'kera_auth_token';
  static const String secureStorageRefreshTokenKey = 'kera_refresh_token';
  static const String secureStorageOwnerIdKey = 'kera_owner_id';
  static const String localePreferenceKey = 'kera_user_locale';
  static const String themeModePreferenceKey = 'kera_user_theme_mode';

  static String? _resolvedApiBaseUrl;

  /// Sets the dynamic working API base URL discovered at runtime.
  static void setApiBaseUrl(String url) {
    _resolvedApiBaseUrl = url;
  }

  /// Candidates for Android host connection:
  /// - 127.0.0.1 / localhost: works with `adb reverse tcp:7000 tcp:7000` over USB
  /// - 10.0.2.2: works on official Android Studio QEMU emulator
  /// - 192.168.137.43: works over local Wi-Fi / hotspot
  static List<String> get candidateAndroidBaseUrls => const [
        'http://127.0.0.1:7000/api/v1',
        'http://10.0.2.2:7000/api/v1',
        'http://192.168.137.43:7000/api/v1',
      ];

  /// API Configuration loaded from runtime detection or --dart-define
  static String get apiBaseUrl {
    if (_resolvedApiBaseUrl != null && _resolvedApiBaseUrl!.isNotEmpty) {
      return _resolvedApiBaseUrl!;
    }
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:7000/api/v1';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:7000/api/v1';
    }
    return 'http://localhost:7000/api/v1';
  }


  /// Touch targets for low-end Android mobile accessibility.
  static const double minTouchTargetSize = 48.0;
  static const double standardButtonHeight = 52.0;
}
